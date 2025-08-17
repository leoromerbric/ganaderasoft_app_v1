import 'package:flutter/material.dart';
import '../models/configuration_item.dart';
import '../services/configuration_service.dart';
import '../services/connectivity_service.dart';
import '../constants/app_constants.dart';
import 'configuration_list_screen.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  bool _isOffline = false;
  bool _isLoading = true;
  Map<String, int> _configurationCounts = {};
  Map<String, bool> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadConfigurationData();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadConfigurationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final counts = await ConfigurationService.getConfigurationCounts();
      final syncStatus = await ConfigurationService.getSyncStatus();
      
      setState(() {
        _configurationCounts = counts;
        _syncStatus = syncStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de configuración: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncAllConfigurations() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay conexión a internet para sincronizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ConfigurationService.syncAllConfigurations();
      await _loadConfigurationData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos de configuración sincronizados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Datos de Configuración'),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _syncAllConfigurations,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync),
            tooltip: 'Sincronizar todos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity status banner
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                border: Border.all(color: Colors.orange, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.orange[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo offline - Los datos se cargan desde caché local',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ConfigurationType.all.length,
                  itemBuilder: (context, index) {
                    final tipo = ConfigurationType.all[index];
                    final displayName = ConfigurationType.getDisplayName(tipo);
                    final count = _configurationCounts[tipo] ?? 0;
                    final isSynced = _syncStatus[tipo] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForType(tipo),
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('$count registros'),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  isSynced ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: isSynced ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSynced ? 'Sincronizado' : 'Sin sincronizar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSynced ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfigurationListScreen(
                                tipo: tipo,
                                displayName: displayName,
                              ),
                            ),
                          ).then((_) => _loadConfigurationData());
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case ConfigurationType.estadoSalud:
        return Icons.health_and_safety;
      case ConfigurationType.etapas:
        return Icons.timeline;
      case ConfigurationType.fuenteAgua:
        return Icons.water_drop;
      case ConfigurationType.metodoRiego:
        return Icons.shower;
      case ConfigurationType.phSuelo:
        return Icons.science;
      case ConfigurationType.sexo:
        return Icons.pets;
      case ConfigurationType.texturaSuelo:
        return Icons.terrain;
      case ConfigurationType.tipoExplotacion:
        return Icons.agriculture;
      case ConfigurationType.tipoRelieve:
        return Icons.landscape;
      case ConfigurationType.tiposAnimal:
        return Icons.cruelty_free;
      default:
        return Icons.settings;
    }
  }
}