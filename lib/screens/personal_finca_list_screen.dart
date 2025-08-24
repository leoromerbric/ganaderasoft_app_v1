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
  List<PersonalFinca> _personal = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPersonal();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadPersonal() async {
    try {
      LoggingService.info(
        'Loading personal finca for finca ${widget.finca.idFinca}',
        'PersonalFincaListScreen',
      );

      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      final personalResponse = await _authService.getPersonalFinca(
        idFinca: widget.finca.idFinca,
      );

      LoggingService.info(
        'Personal finca loaded successfully (${personalResponse.data.length} items)',
        'PersonalFincaListScreen',
      );

      setState(() {
        _personal = personalResponse.data;
        _isLoading = false;
        _dataSourceMessage = personalResponse.message;
      });
    } catch (e) {
      LoggingService.error('Error loading personal finca', 'PersonalFincaListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTipoTrabajadorIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'veterinario':
        return '🐕';
      case 'tecnico':
        return '🔧';
      case 'vigilante':
        return '🛡️';
      case 'administrador':
        return '📊';
      default:
        return '👤';
    }
  }

  Color _getTipoTrabajadorColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'veterinario':
        return Colors.green;
      case 'tecnico':
        return Colors.blue;
      case 'vigilante':
        return Colors.orange;
      case 'administrador':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal de la Finca'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar personal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadPersonal,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
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
                      color: _isOffline ? Colors.orange[100] : Colors.green[100],
                      border: Border.all(
                        color: _isOffline ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done,
                          color: _isOffline ? Colors.orange[800] : Colors.green[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dataSourceMessage!,
                            style: TextStyle(
                              color: _isOffline ? Colors.orange[800] : Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Count info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_personal.length} empleado${_personal.length != 1 ? 's' : ''} registrado${_personal.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _personal.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay personal registrado',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega el primer empleado',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPersonal,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _personal.length,
                            itemBuilder: (context, index) {
                              final persona = _personal[index];
                              return _buildPersonalCard(persona);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePersonalFincaScreen(
                finca: widget.finca,
              ),
            ),
          );

          if (result == true) {
            _loadPersonal();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar empleado',
      ),
    );
  }

  Widget _buildPersonalCard(PersonalFinca persona) {
    final tipoColor = _getTipoTrabajadorColor(persona.tipoTrabajador);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and type
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tipoColor.withOpacity(0.1),
                  child: Text(
                    _getTipoTrabajadorIcon(persona.tipoTrabajador),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${persona.nombre} ${persona.apellido}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tipoColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          persona.tipoTrabajador,
                          style: TextStyle(
                            color: tipoColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact info
            _buildInfoRow(
              Icons.badge,
              'Cédula',
              persona.cedula.toString(),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone,
              'Teléfono',
              persona.telefono,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.email,
              'Correo',
              persona.correo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
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