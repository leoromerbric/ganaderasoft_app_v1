import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  StreamSubscription<SyncData>? _syncSubscription;
  SyncData _currentSyncData = SyncData(status: SyncStatus.idle);
  Map<String, DateTime?> _lastSyncTimes = {};

  @override
  void initState() {
    super.initState();
    _loadLastSyncTimes();
    _subscribeToSync();
  }

  Future<void> _loadLastSyncTimes() async {
    final times = await SyncService.getLastSyncTimes();
    setState(() {
      _lastSyncTimes = times;
    });
  }

  void _subscribeToSync() {
    _syncSubscription = SyncService.syncStream.listen((syncData) {
      setState(() {
        _currentSyncData = syncData;
      });

      if (syncData.status == SyncStatus.success) {
        _loadLastSyncTimes();
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startSync() async {
    await SyncService.syncData();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Nunca sincronizado';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace menos de un minuto';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar Datos Online'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getStatusTitle(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentSyncData.message != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _currentSyncData.message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          if (_currentSyncData.status ==
                              SyncStatus.syncing) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _currentSyncData.progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_currentSyncData.progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Last sync times
                  Text(
                    'Información de Sincronización',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSyncInfoCard(
                    'Datos del Usuario',
                    _lastSyncTimes['user'],
                    Icons.person,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Datos de Fincas',
                    _lastSyncTimes['fincas'],
                    Icons.agriculture,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Rebaños',
                    _lastSyncTimes['rebanos'],
                    Icons.groups,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Animales',
                    _lastSyncTimes['animales'],
                    Icons.pets,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Estado de Salud',
                    _lastSyncTimes['estado_salud'],
                    Icons.health_and_safety,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Tipo de Animal',
                    _lastSyncTimes['tipo_animal'],
                    Icons.category,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Etapas',
                    _lastSyncTimes['etapas'],
                    Icons.timeline,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Fuente de Agua',
                    _lastSyncTimes['fuente_agua'],
                    Icons.water_drop,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Método de Riego',
                    _lastSyncTimes['metodo_riego'],
                    Icons.water,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'pH de Suelo',
                    _lastSyncTimes['ph_suelo'],
                    Icons.analytics,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Sexo',
                    _lastSyncTimes['sexo'],
                    Icons.person,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Textura de Suelo',
                    _lastSyncTimes['textura_suelo'],
                    Icons.terrain,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Tipo de Exposición',
                    _lastSyncTimes['tipo_explotacion'],
                    Icons.agriculture,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Tipo de Relieve',
                    _lastSyncTimes['tipo_relieve'],
                    Icons.landscape,
                  ),
                  const SizedBox(height: 12),

                  _buildSyncInfoCard(
                    'Composición de Raza',
                    _lastSyncTimes['composicion_raza'],
                    Icons.pets,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed sync button at bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentSyncData.status == SyncStatus.syncing
                    ? null
                    : _startSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 192, 212, 59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _currentSyncData.status == SyncStatus.syncing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sincronizando...'),
                        ],
                      )
                    : const Text(
                        'Sincronizar Ahora',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 38, 39, 37),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncInfoCard(String title, DateTime? lastSync, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última sincronización: ${_formatDateTime(lastSync)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentSyncData.status) {
      case SyncStatus.idle:
        return Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (_currentSyncData.status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Theme.of(context).colorScheme.primary;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  String _getStatusTitle() {
    switch (_currentSyncData.status) {
      case SyncStatus.idle:
        return 'Listo para sincronizar';
      case SyncStatus.syncing:
        return 'Sincronizando datos...';
      case SyncStatus.success:
        return 'Sincronización completada';
      case SyncStatus.error:
        return 'Error en la sincronización';
    }
  }
}
