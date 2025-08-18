import 'package:flutter/material.dart';
import '../models/configuration_models.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../constants/app_constants.dart';

class ConfigurationDataScreen extends StatefulWidget {
  const ConfigurationDataScreen({super.key});

  @override
  State<ConfigurationDataScreen> createState() =>
      _ConfigurationDataScreenState();
}

class _ConfigurationDataScreenState extends State<ConfigurationDataScreen> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Datos Maestros'),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.offline_bolt, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Datos cargados desde caché local',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Selecciona el tipo de configuración',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildConfigurationCard(
                    context,
                    'Estados de Salud',
                    Icons.health_and_safety,
                    'Ver estados de salud de animales',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.estadoSalud,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Tipos de Animal',
                    Icons.pets,
                    'Ver tipos de animales',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.tipoAnimal,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Etapas',
                    Icons.timeline,
                    'Ver etapas de desarrollo',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.etapa,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Fuente de Agua',
                    Icons.water_drop,
                    'Ver fuentes de agua',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.fuenteAgua,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Método de Riego',
                    Icons.water,
                    'Ver métodos de riego',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.metodoRiego,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'pH de Suelo',
                    Icons.analytics,
                    'Ver niveles de pH',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.phSuelo,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Sexo',
                    Icons.person,
                    'Ver tipos de sexo',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.sexo,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Textura de Suelo',
                    Icons.terrain,
                    'Ver texturas de suelo',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.texturaSuelo,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Tipo de Explotación',
                    Icons.agriculture,
                    'Ver tipos de explotación',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.tipoExplotacion,
                    ),
                  ),
                  _buildConfigurationCard(
                    context,
                    'Tipo de Relieve',
                    Icons.landscape,
                    'Ver tipos de relieve',
                    () => _navigateToDetailScreen(
                      context,
                      ConfigurationType.tipoRelieve,
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

  Widget _buildConfigurationCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetailScreen(BuildContext context, ConfigurationType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConfigurationDetailScreen(configurationType: type),
      ),
    );
  }
}

enum ConfigurationType {
  estadoSalud,
  tipoAnimal,
  etapa,
  fuenteAgua,
  metodoRiego,
  phSuelo,
  sexo,
  texturaSuelo,
  tipoExplotacion,
  tipoRelieve,
}

class ConfigurationDetailScreen extends StatefulWidget {
  final ConfigurationType configurationType;

  const ConfigurationDetailScreen({super.key, required this.configurationType});

  @override
  State<ConfigurationDetailScreen> createState() =>
      _ConfigurationDetailScreenState();
}

class _ConfigurationDetailScreenState extends State<ConfigurationDetailScreen> {
  bool _isOffline = false;
  bool _isLoading = true;
  List<dynamic> _data = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadData();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      List<dynamic> data = [];

      switch (widget.configurationType) {
        case ConfigurationType.estadoSalud:
          data = await DatabaseService.getEstadosSaludOffline();
          break;
        case ConfigurationType.tipoAnimal:
          data = await DatabaseService.getTiposAnimalOffline();
          break;
        case ConfigurationType.etapa:
          data = await DatabaseService.getEtapasOffline();
          break;
        case ConfigurationType.fuenteAgua:
          data = await DatabaseService.getFuenteAguaOffline();
          break;
        case ConfigurationType.metodoRiego:
          data = await DatabaseService.getMetodoRiegoOffline();
          break;
        case ConfigurationType.phSuelo:
          data = await DatabaseService.getPhSueloOffline();
          break;
        case ConfigurationType.sexo:
          data = await DatabaseService.getSexoOffline();
          break;
        case ConfigurationType.texturaSuelo:
          data = await DatabaseService.getTexturaSueloOffline();
          break;
        case ConfigurationType.tipoExplotacion:
          data = await DatabaseService.getTipoExplotacionOffline();
          break;
        case ConfigurationType.tipoRelieve:
          data = await DatabaseService.getTipoRelieveOffline();
          break;
      }

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String get _title {
    switch (widget.configurationType) {
      case ConfigurationType.estadoSalud:
        return 'Estados de Salud';
      case ConfigurationType.tipoAnimal:
        return 'Tipos de Animal';
      case ConfigurationType.etapa:
        return 'Etapas';
      case ConfigurationType.fuenteAgua:
        return 'Fuente de Agua';
      case ConfigurationType.metodoRiego:
        return 'Método de Riego';
      case ConfigurationType.phSuelo:
        return 'pH de Suelo';
      case ConfigurationType.sexo:
        return 'Sexo';
      case ConfigurationType.texturaSuelo:
        return 'Textura de Suelo';
      case ConfigurationType.tipoExplotacion:
        return 'Tipo de Explotación';
      case ConfigurationType.tipoRelieve:
        return 'Tipo de Relieve';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_title),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.offline_bolt, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mostrando datos desde caché local',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta sincronizar datos para obtener información actualizada',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final item = _data[index];
        return _buildDataCard(item);
      },
    );
  }

  Widget _buildDataCard(dynamic item) {
    String title = '';
    String subtitle = '';
    bool synced = false;

    if (item is EstadoSalud) {
      title = item.estadoNombre;
      subtitle = 'ID: ${item.estadoId}';
      synced = item.synced ?? false;
    } else if (item is TipoAnimal) {
      title = item.tipoAnimalNombre;
      subtitle = 'ID: ${item.tipoAnimalId}';
      synced = item.synced ?? false;
    } else if (item is Etapa) {
      title = item.etapaNombre;
      subtitle =
          '${item.etapaEdadIni} - ${item.etapaEdadFin ?? "∞"} días | ${item.tipoAnimal.tipoAnimalNombre} (${item.etapaSexo})';
      synced = item.synced ?? false;
    } else if (item is FuenteAgua) {
      title = item.nombre;
      subtitle = 'Código: ${item.codigo}';
      synced = item.synced ?? false;
    } else if (item is MetodoRiego) {
      title = item.nombre;
      subtitle = 'Código: ${item.codigo}';
      synced = item.synced ?? false;
    } else if (item is PhSuelo) {
      title = item.nombre;
      subtitle = '${item.descripcion} (${item.codigo})';
      synced = item.synced ?? false;
    } else if (item is Sexo) {
      title = item.nombre;
      subtitle = 'Código: ${item.codigo}';
      synced = item.synced ?? false;
    } else if (item is TexturaSuelo) {
      title = item.nombre;
      subtitle = 'Código: ${item.codigo}';
      synced = item.synced ?? false;
    } else if (item is TipoExplotacion) {
      title = item.nombre;
      subtitle = 'Código: ${item.codigo}';
      synced = item.synced ?? false;
    } else if (item is TipoRelieve) {
      title = item.valor;
      subtitle = '${item.descripcion} (ID: ${item.id})';
      synced = item.synced ?? false;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: synced ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: synced
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    synced ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: synced
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    synced ? 'Sincronizado' : 'Local',
                    style: TextStyle(
                      fontSize: 12,
                      color: synced
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
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
}
