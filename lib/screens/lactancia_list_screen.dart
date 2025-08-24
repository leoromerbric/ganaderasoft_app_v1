import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_lactancia_screen.dart';

class LactanciaListScreen extends StatefulWidget {
  final Finca finca;

  const LactanciaListScreen({
    super.key,
    required this.finca,
  });

  @override
  State<LactanciaListScreen> createState() => _LactanciaListScreenState();
}

class _LactanciaListScreenState extends State<LactanciaListScreen> {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  String? _dataSourceMessage;
  List<Lactancia> _lactancias = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadLactancias();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
      _dataSourceMessage = _isOffline
          ? 'Mostrando datos guardados localmente'
          : 'Mostrando datos sincronizados';
    });
  }

  Future<void> _loadLactancias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // This would need to be implemented in AuthService
      // For now, create an empty response
      setState(() {
        _lactancias = [];
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Error loading lactancias', 'LactanciaListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lactancias'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Sin conexión',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_dataSourceMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isOffline ? Colors.orange[50] : Colors.green[50],
              child: Row(
                children: [
                  Icon(
                    _isOffline ? Icons.cloud_off : Icons.cloud_done,
                    size: 16,
                    color: _isOffline
                        ? Colors.orange[700]
                        : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dataSourceMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOffline
                            ? Colors.orange[800]
                            : Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildLactanciasList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateLactanciaScreen(finca: widget.finca),
            ),
          );

          if (result != null) {
            // Refresh the list
            _loadLactancias();
          }
        },
        tooltip: 'Registrar Lactancia',
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLactanciasList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar lactancias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLactancias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_lactancias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pregnant_woman,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay lactancias registradas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Las lactancias aparecerán aquí cuando sean registradas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLactancias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _lactancias.length,
        itemBuilder: (context, index) {
          final lactancia = _lactancias[index];
          return _buildLactanciaCard(lactancia);
        },
      ),
    );
  }

  Widget _buildLactanciaCard(Lactancia lactancia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.pregnant_woman,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lactancia #${lactancia.lactanciaId}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(lactancia.lactanciaFechaInicio),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animal info
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Animal ID: ${lactancia.lactanciaEtapaAnid} - Etapa ID: ${lactancia.lactanciaEtapaEtid}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lactancia details
            _buildDetailRow('Fecha Inicio', _formatDate(lactancia.lactanciaFechaInicio)),
            if (lactancia.lactanciaFechaFin != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Fecha Fin', _formatDate(lactancia.lactanciaFechaFin!)),
            ],
            if (lactancia.lactanciaSecado != null && lactancia.lactanciaSecado!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Secado', lactancia.lactanciaSecado!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}