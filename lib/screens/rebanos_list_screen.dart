import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'animales_list_screen.dart';

class RebanosListScreen extends StatefulWidget {
  final Finca finca;

  const RebanosListScreen({
    super.key,
    required this.finca,
  });

  @override
  State<RebanosListScreen> createState() => _RebanosListScreenState();
}

class _RebanosListScreenState extends State<RebanosListScreen> {
  final _authService = AuthService();
  List<Rebano> _rebanos = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadRebanos();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadRebanos() async {
    try {
      LoggingService.info('Loading rebanos for finca ${widget.finca.idFinca}', 'RebanosListScreen');
      
      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      final rebanosResponse = await _authService.getRebanos(
        idFinca: widget.finca.idFinca,
      );
      
      LoggingService.info('Rebanos loaded successfully (${rebanosResponse.rebanos.length} items)', 'RebanosListScreen');
      
      setState(() {
        _rebanos = rebanosResponse.rebanos;
        _isLoading = false;
        _dataSourceMessage = rebanosResponse.message;
      });
    } catch (e) {
      LoggingService.error('Error loading rebanos', 'RebanosListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rebaños'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar rebaños',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadRebanos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _rebanos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay rebaños registrados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los rebaños de esta finca aparecerán aquí cuando sean registrados',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Data source info banner
                        if (_dataSourceMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(16).copyWith(bottom: 8),
                            decoration: BoxDecoration(
                              color: _isOffline ? Colors.orange[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isOffline ? Colors.orange[200]! : Colors.green[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isOffline ? Icons.cloud_off : Icons.cloud_done,
                                  size: 16,
                                  color: _isOffline ? Colors.orange[700] : Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dataSourceMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isOffline ? Colors.orange[800] : Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(child: _buildRebanosList()),
                      ],
                    ),
    );
  }

  Widget _buildRebanosList() {
    return RefreshIndicator(
      onRefresh: _loadRebanos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _rebanos.length,
        itemBuilder: (context, index) {
          final rebano = _rebanos[index];
          return _buildRebanoCard(rebano);
        },
      ),
    );
  }

  Widget _buildRebanoCard(Rebano rebano) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimalesListScreen(
                finca: widget.finca,
                rebanos: [rebano],
                selectedRebano: rebano,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rebano.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animal count
              if (rebano.animales != null && rebano.animales!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rebano.animales!.length} animal${rebano.animales!.length != 1 ? 'es' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      'Creado',
                      _formatDate(rebano.createdAt),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInfo(
                      'Actualizado',
                      _formatDate(rebano.updatedAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}