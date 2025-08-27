import 'dart:async';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/configuration_service.dart';
import '../services/logging_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncData {
  final SyncStatus status;
  final String? message;
  final double progress;

  SyncData({required this.status, this.message, this.progress = 0.0});
}

class SyncService {
  static final StreamController<SyncData> _syncController =
      StreamController<SyncData>.broadcast();
  static final AuthService _authService = AuthService();

  static Stream<SyncData> get syncStream => _syncController.stream;

  static Future<bool> syncData() async {
    LoggingService.info('Starting data synchronization...', 'SyncService');

    try {
      // Check connectivity
      if (!await ConnectivityService.isConnected()) {
        LoggingService.warning(
          'No internet connection for sync',
          'SyncService',
        );
        _syncController.add(
          SyncData(
            status: SyncStatus.error,
            message: 'No hay conexión a internet',
          ),
        );
        return false;
      }

      LoggingService.info(
        'Connection available, proceeding with sync',
        'SyncService',
      );

      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Iniciando sincronización...',
          progress: 0.05,
        ),
      );

      // Sync user data
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando datos del usuario...',
          progress: 0.1,
        ),
      );

      try {
        LoggingService.debug('Syncing user profile data...', 'SyncService');
        final user = await _authService.getProfile();
        await DatabaseService.saveUserOffline(user);
        await _authService.saveUser(user);
        LoggingService.info(
          'User data synchronized successfully',
          'SyncService',
        );
      } catch (e) {
        LoggingService.error('Error synchronizing user data', 'SyncService', e);
        _syncController.add(
          SyncData(
            status: SyncStatus.error,
            message: 'Error al sincronizar usuario: ${e.toString()}',
          ),
        );
        return false;
      }

      // Sync fincas data
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando datos de fincas...',
          progress: 0.2,
        ),
      );

      try {
        LoggingService.debug('Syncing fincas data...', 'SyncService');
        final fincasResponse = await _authService.getFincas();
        await DatabaseService.saveFincasOffline(fincasResponse.fincas);
        LoggingService.info(
          'Fincas data synchronized successfully (${fincasResponse.fincas.length} items)',
          'SyncService',
        );
      } catch (e) {
        LoggingService.error(
          'Error synchronizing fincas data',
          'SyncService',
          e,
        );
        _syncController.add(
          SyncData(
            status: SyncStatus.error,
            message: 'Error al sincronizar fincas: ${e.toString()}',
          ),
        );
        return false;
      }

      // Sync rebanos data
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando datos de rebaños...',
          progress: 0.25,
        ),
      );

      try {
        LoggingService.debug('Syncing rebanos data...', 'SyncService');
        final rebanosResponse = await _authService.getRebanos();
        await DatabaseService.saveRebanosOffline(rebanosResponse.rebanos);
        LoggingService.info(
          'Rebanos data synchronized successfully (${rebanosResponse.rebanos.length} items)',
          'SyncService',
        );
      } catch (e) {
        LoggingService.error(
          'Error synchronizing rebanos data',
          'SyncService',
          e,
        );
        _syncController.add(
          SyncData(
            status: SyncStatus.error,
            message: 'Error al sincronizar rebaños: ${e.toString()}',
          ),
        );
        return false;
      }

      // Sync animales data
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando datos de animales...',
          progress: 0.3,
        ),
      );

      try {
        LoggingService.debug('Syncing animales data...', 'SyncService');
        final animalesResponse = await _authService.getAnimales();
        await DatabaseService.saveAnimalesOffline(animalesResponse.animales);
        
        // Sync animal details for each animal
        LoggingService.debug('Syncing animal details...', 'SyncService');
        int totalAnimals = animalesResponse.animales.length;
        int syncedAnimals = 0;
        
        for (final animal in animalesResponse.animales) {
          try {
            final animalDetailResponse = await _authService.getAnimalDetail(animal.idAnimal);
            await DatabaseService.saveAnimalDetailOffline(animalDetailResponse.data);
            syncedAnimals++;
            
            // Update progress for animal detail sync
            double detailProgress = 0.3 + (0.2 * syncedAnimals / totalAnimals);
            _syncController.add(
              SyncData(
                status: SyncStatus.syncing,
                message: 'Sincronizando detalles de animales... ($syncedAnimals/$totalAnimals)',
                progress: detailProgress,
              ),
            );
          } catch (e) {
            LoggingService.warning(
              'Failed to sync detail for animal ${animal.idAnimal}: $e',
              'SyncService',
            );
            // Continue with other animals even if one fails
          }
        }
        
        LoggingService.info(
          'Animales data synchronized successfully (${animalesResponse.animales.length} items, $syncedAnimals details)',
          'SyncService',
        );
      } catch (e) {
        LoggingService.error(
          'Error synchronizing animales data',
          'SyncService',
          e,
        );
        _syncController.add(
          SyncData(
            status: SyncStatus.error,
            message: 'Error al sincronizar animales: ${e.toString()}',
          ),
        );
        return false;
      }

      // Sync new farm management entities
      await _syncFarmManagementData();

      // Sync configuration data
      await _syncConfigurationData();

      LoggingService.info(
        'Data synchronization completed successfully',
        'SyncService',
      );
      _syncController.add(
        SyncData(
          status: SyncStatus.success,
          message: 'Sincronización completada exitosamente',
          progress: 1.0,
        ),
      );

      return true;
    } catch (e) {
      LoggingService.error(
        'Unexpected error during synchronization',
        'SyncService',
        e,
      );
      _syncController.add(
        SyncData(
          status: SyncStatus.error,
          message: 'Error inesperado: ${e.toString()}',
        ),
      );
      return false;
    }
  }

  static Future<void> _syncConfigurationData() async {
    LoggingService.info(
      'Starting configuration data synchronization...',
      'SyncService',
    );

    try {
      // Estados de Salud
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando estados de salud...',
          progress: 0.55,
        ),
      );

      final estadosSaludResponse = await ConfigurationService.getEstadosSalud();
      await DatabaseService.saveEstadosSaludOffline(
        estadosSaludResponse.data.data,
      );
      LoggingService.info(
        'Estados de salud synchronized: ${estadosSaludResponse.data.data.length} items',
        'SyncService',
      );

      // Tipos de Animal
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando tipos de animal...',
          progress: 0.6,
        ),
      );

      final tiposAnimalResponse = await ConfigurationService.getTiposAnimal();
      await DatabaseService.saveTiposAnimalOffline(
        tiposAnimalResponse.data.data,
      );
      LoggingService.info(
        'Tipos de animal synchronized: ${tiposAnimalResponse.data.data.length} items',
        'SyncService',
      );

      // Etapas
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando etapas...',
          progress: 0.95,
        ),
      );

      final etapas = await ConfigurationService.getEtapas();
      await DatabaseService.saveEtapasOffline(etapas);
      LoggingService.info(
        'Etapas synchronized: ${etapas.length} items',
        'SyncService',
      );

      // Fuente Agua
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando fuente de agua...',
          progress: 0.98,
        ),
      );

      final fuenteAgua = await ConfigurationService.getFuenteAgua();
      await DatabaseService.saveFuenteAguaOffline(fuenteAgua);
      LoggingService.info(
        'Fuente agua synchronized: ${fuenteAgua.length} items',
        'SyncService',
      );

      // Método Riego
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando métodos de riego...',
          progress: 0.95,
        ),
      );

      final metodoRiego = await ConfigurationService.getMetodoRiego();
      await DatabaseService.saveMetodoRiegoOffline(metodoRiego);
      LoggingService.info(
        'Método riego synchronized: ${metodoRiego.length} items',
        'SyncService',
      );

      // pH Suelo
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando pH de suelo...',
          progress: 0.98,
        ),
      );

      final phSuelo = await ConfigurationService.getPhSuelo();
      await DatabaseService.savePhSueloOffline(phSuelo);
      LoggingService.info(
        'pH suelo synchronized: ${phSuelo.length} items',
        'SyncService',
      );

      // Sexo
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando datos de sexo...',
          progress: 0.95,
        ),
      );

      final sexo = await ConfigurationService.getSexo();
      await DatabaseService.saveSexoOffline(sexo);
      LoggingService.info(
        'Sexo synchronized: ${sexo.length} items',
        'SyncService',
      );

      // Textura Suelo
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando textura de suelo...',
          progress: 0.98,
        ),
      );

      final texturaSuelo = await ConfigurationService.getTexturaSuelo();
      await DatabaseService.saveTexturaSueloOffline(texturaSuelo);
      LoggingService.info(
        'Textura suelo synchronized: ${texturaSuelo.length} items',
        'SyncService',
      );

      // Tipo Explotación
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando tipos de explotación...',
          progress: 0.95,
        ),
      );

      final tipoExplotacion = await ConfigurationService.getTipoExplotacion();
      await DatabaseService.saveTipoExplotacionOffline(tipoExplotacion);
      LoggingService.info(
        'Tipo explotación synchronized: ${tipoExplotacion.length} items',
        'SyncService',
      );

      // Tipo Relieve
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando tipos de relieve...',
          progress: 0.95,
        ),
      );

      final tipoRelieve = await ConfigurationService.getTipoRelieve();
      await DatabaseService.saveTipoRelieveOffline(tipoRelieve);
      LoggingService.info(
        'Tipo relieve synchronized: ${tipoRelieve.length} items',
        'SyncService',
      );

      // Composición Raza
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando composición de raza...',
          progress: 0.98,
        ),
      );

      final composicionRazaResponse =
          await ConfigurationService.getComposicionRaza();
      await DatabaseService.saveComposicionRazaOffline(
        composicionRazaResponse.data.data,
      );
      LoggingService.info(
        'Composición raza synchronized: ${composicionRazaResponse.data.data.length} items',
        'SyncService',
      );

      LoggingService.info(
        'Configuration data synchronization completed successfully',
        'SyncService',
      );
    } catch (e) {
      LoggingService.error(
        'Error synchronizing configuration data',
        'SyncService',
        e,
      );
      rethrow;
    }
  }

  static Future<Map<String, DateTime?>> getLastSyncTimes() async {
    LoggingService.debug('Getting last sync times...', 'SyncService');

    final lastSyncTimes = {
      'user': await DatabaseService.getUserLastUpdated(),
      'fincas': await DatabaseService.getFincasLastUpdated(),
      'rebanos': await DatabaseService.getRebanosLastUpdated(),
      'animales': await DatabaseService.getAnimalesLastUpdated(),
      'estado_salud': await DatabaseService.getConfigurationLastUpdated(
        'estado_salud',
      ),
      'tipo_animal': await DatabaseService.getConfigurationLastUpdated(
        'tipo_animal',
      ),
      'etapas': await DatabaseService.getConfigurationLastUpdated('etapa'),
      'fuente_agua': await DatabaseService.getConfigurationLastUpdated(
        'fuente_agua',
      ),
      'metodo_riego': await DatabaseService.getConfigurationLastUpdated(
        'metodo_riego',
      ),
      'ph_suelo': await DatabaseService.getConfigurationLastUpdated('ph_suelo'),
      'sexo': await DatabaseService.getConfigurationLastUpdated('sexo'),
      'textura_suelo': await DatabaseService.getConfigurationLastUpdated(
        'textura_suelo',
      ),
      'tipo_explotacion': await DatabaseService.getConfigurationLastUpdated(
        'tipo_explotacion',
      ),
      'tipo_relieve': await DatabaseService.getConfigurationLastUpdated(
        'tipo_relieve',
      ),
      'composicion_raza': await DatabaseService.getConfigurationLastUpdated(
        'composicion_raza',
      ),
      // Farm management data
      'cambios_animal': await DatabaseService.getCambiosAnimalLastUpdated(),
      'peso_corporal': await DatabaseService.getPesoCorporalLastUpdated(),
      'personal_finca': await DatabaseService.getPersonalFincaLastUpdated(),
      'lactancia': await DatabaseService.getLactanciaLastUpdated(),
    };

    LoggingService.debug(
      'Last sync times retrieved: ${lastSyncTimes.toString()}',
      'SyncService',
    );
    return lastSyncTimes;
  }

  static Future<void> _syncFarmManagementData() async {
    try {
      LoggingService.info(
        'Starting farm management data synchronization',
        'SyncService',
      );

      // Sync Cambios Animal
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando cambios de animales...',
          progress: 0.52,
        ),
      );

      try {
        LoggingService.debug('Syncing cambios animal data...', 'SyncService');
        final cambiosResponse = await _authService.getCambiosAnimal();
        await DatabaseService.saveCambiosAnimalOffline(cambiosResponse.data);
        LoggingService.info(
          'Cambios animal synchronized: ${cambiosResponse.data.length} items',
          'SyncService',
        );
      } catch (e) {
        LoggingService.warning(
          'Failed to sync cambios animal data: $e',
          'SyncService',
        );
      }

      // Sync Peso Corporal
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando peso corporal...',
          progress: 0.54,
        ),
      );

      try {
        LoggingService.debug('Syncing peso corporal data...', 'SyncService');
        final pesoResponse = await _authService.getPesoCorporal();
        await DatabaseService.savePesoCorporalOffline(pesoResponse.data);
        LoggingService.info(
          'Peso corporal synchronized: ${pesoResponse.data.length} items',
          'SyncService',
        );
      } catch (e) {
        LoggingService.warning(
          'Failed to sync peso corporal data: $e',
          'SyncService',
        );
      }

      // Sync Personal Finca
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando personal de finca...',
          progress: 0.56,
        ),
      );

      try {
        LoggingService.debug('Syncing personal finca data...', 'SyncService');
        final personalResponse = await _authService.getPersonalFinca();
        await DatabaseService.savePersonalFincaOffline(personalResponse.data);
        LoggingService.info(
          'Personal finca synchronized: ${personalResponse.data.length} items',
          'SyncService',
        );
      } catch (e) {
        LoggingService.warning(
          'Failed to sync personal finca data: $e',
          'SyncService',
        );
      }

      // Sync Lactancia
      _syncController.add(
        SyncData(
          status: SyncStatus.syncing,
          message: 'Sincronizando registros de lactancia...',
          progress: 0.58,
        ),
      );

      try {
        LoggingService.debug('Syncing lactancia data...', 'SyncService');
        final lactanciaResponse = await _authService.getLactancia();
        await DatabaseService.saveLactanciaOffline(lactanciaResponse.data);
        LoggingService.info(
          'Lactancia synchronized: ${lactanciaResponse.data.length} items',
          'SyncService',
        );
      } catch (e) {
        LoggingService.warning(
          'Failed to sync lactancia data: $e',
          'SyncService',
        );
      }

      LoggingService.info(
        'Farm management data synchronization completed',
        'SyncService',
      );
    } catch (e) {
      LoggingService.error(
        'Farm management data sync encountered issues (non-critical)',
        'SyncService',
        e,
      );
      // Don't fail the entire sync for farm management data issues
    }
  }

  static void dispose() {
    LoggingService.debug('Disposing SyncService', 'SyncService');
    _syncController.close();
  }
}
