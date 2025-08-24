import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_personal_finca_screen.dart';

class PersonalFincaListScreen extends StatefulWidget {
  final Finca finca;

  const PersonalFincaListScreen({
    super.key,
    required this.finca,
  });

  @override
  State<PersonalFincaListScreen> createState() => _PersonalFincaListScreenState();
}

class _PersonalFincaListScreenState extends State<PersonalFincaListScreen> {
  final _authService = AuthService();
  List<PersonalFinca> _personalFinca = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPersonalFinca();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadPersonalFinca() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final personalResponse = await _authService.getPersonalFinca(
        fincaId: widget.finca.idFinca,
      );

      setState(() {
        _personalFinca = personalResponse.personalFinca;
        _isLoading = false;
        _dataSourceMessage = _isOffline 
            ? 'Datos desde caché local (sin conexión)'
            : 'Datos actualizados desde el servidor';
      });

      LoggingService.info(
        'Personal finca loaded successfully (${_personalFinca.length} items)',
        'PersonalFincaListScreen',
      );
    } catch (e) {
      LoggingService.error('Error loading personal finca', 'PersonalFincaListScreen', e);
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

  String _formatSalary(double salario) {
    return '\$${salario.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal de la Finca'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status indicator
          if (_dataSourceMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isOffline ? Colors.orange[100] : Colors.green[100],
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
          Expanded(child: _buildPersonalFincaList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePersonalFincaScreen(finca: widget.finca),
            ),
          );

          if (result != null) {
            // Refresh the list
            _loadPersonalFinca();
          }
        },
        tooltip: 'Agregar Personal',
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPersonalFincaList() {
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
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el personal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPersonalFinca,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_personalFinca.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay personal registrado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'El personal de la finca aparecerá aquí cuando sea registrado',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPersonalFinca,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _personalFinca.length,
        itemBuilder: (context, index) {
          final personal = _personalFinca[index];
          return _buildPersonalCard(personal);
        },
      ),
    );
  }

  Widget _buildPersonalCard(PersonalFinca personal) {
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
                CircleAvatar(
                  backgroundColor: personal.activo 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: personal.activo 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${personal.nombre} ${personal.apellido}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                          personal.cargo,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!personal.activo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Inactivo',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact info
            _buildDetailRow('Teléfono', personal.telefono, Icons.phone),
            if (personal.email != null && personal.email!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Email', personal.email!, Icons.email),
            ],
            const SizedBox(height: 8),
            _buildDetailRow('Fecha de Ingreso', _formatDate(personal.fechaIngreso), Icons.calendar_today),
            const SizedBox(height: 8),
            _buildDetailRow('Salario', _formatSalary(personal.salario), Icons.attach_money),
            
            if (personal.observaciones != null && personal.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Observaciones', personal.observaciones!, Icons.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
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