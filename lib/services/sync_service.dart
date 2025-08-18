import 'dart:async';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/configuration_service.dart';
import '../services/logging_service.dart';
import '../models/user.dart';
import '../models/finca.dart';
import '../models/animal.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncData {
  final SyncStatus status;
  final String? message;
  final double progress;

  SyncData({
    required this.status,
    this.message,
    this.progress = 0.0,
  });
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
        LoggingService.warning('No internet connection for sync', 'SyncService');
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'No hay conexión a internet',
        ));
        return false;
      }

      LoggingService.info('Connection available, proceeding with sync', 'SyncService');

      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Iniciando sincronización...',
        progress: 0.05,
      ));

      // Sync user data
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos del usuario...',
        progress: 0.1,
      ));

      try {
        LoggingService.debug('Syncing user profile data...', 'SyncService');
        final user = await _authService.getProfile();
        await DatabaseService.saveUserOffline(user);
        await _authService.saveUser(user);
        LoggingService.info('User data synchronized successfully', 'SyncService');
      } catch (e) {
        LoggingService.error('Error synchronizing user data', 'SyncService', e);
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'Error al sincronizar usuario: ${e.toString()}',
        ));
        return false;
      }

      // Sync fincas data
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos de fincas...',
        progress: 0.2,
      ));

      try {
        LoggingService.debug('Syncing fincas data...', 'SyncService');
        final fincasResponse = await _authService.getFincas();
        await DatabaseService.saveFincasOffline(fincasResponse.fincas);
        LoggingService.info('Fincas data synchronized successfully (${fincasResponse.fincas.length} items)', 'SyncService');
      } catch (e) {
        LoggingService.error('Error synchronizing fincas data', 'SyncService', e);
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'Error al sincronizar fincas: ${e.toString()}',
        ));
        return false;
      }

      // Sync rebanos data
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos de rebaños...',
        progress: 0.25,
      ));

      try {
        LoggingService.debug('Syncing rebanos data...', 'SyncService');
        final rebanosResponse = await _authService.getRebanos();
        await DatabaseService.saveRebanosOffline(rebanosResponse.rebanos);
        LoggingService.info('Rebanos data synchronized successfully (${rebanosResponse.rebanos.length} items)', 'SyncService');
      } catch (e) {
        LoggingService.error('Error synchronizing rebanos data', 'SyncService', e);
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'Error al sincronizar rebaños: ${e.toString()}',
        ));
        return false;
      }

      // Sync animales data
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos de animales...',
        progress: 0.3,
      ));

      try {
        LoggingService.debug('Syncing animales data...', 'SyncService');
        final animalesResponse = await _authService.getAnimales();
        await DatabaseService.saveAnimalesOffline(animalesResponse.animales);
        LoggingService.info('Animales data synchronized successfully (${animalesResponse.animales.length} items)', 'SyncService');
      } catch (e) {
        LoggingService.error('Error synchronizing animales data', 'SyncService', e);
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'Error al sincronizar animales: ${e.toString()}',
        ));
        return false;
      }

      // Sync configuration data
      await _syncConfigurationData();

      LoggingService.info('Data synchronization completed successfully', 'SyncService');
      _syncController.add(SyncData(
        status: SyncStatus.success,
        message: 'Sincronización completada exitosamente',
        progress: 1.0,
      ));

      return true;
    } catch (e) {
      LoggingService.error('Unexpected error during synchronization', 'SyncService', e);
      _syncController.add(SyncData(
        status: SyncStatus.error,
        message: 'Error inesperado: ${e.toString()}',
      ));
      return false;
    }
  }

  static Future<void> _syncConfigurationData() async {
    LoggingService.info('Starting configuration data synchronization...', 'SyncService');

    try {
      // Estados de Salud
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando estados de salud...',
        progress: 0.35,
      ));
      
      final estadosSaludResponse = await ConfigurationService.getEstadosSalud();
      await DatabaseService.saveEstadosSaludOffline(estadosSaludResponse.data.data);
      LoggingService.info('Estados de salud synchronized: ${estadosSaludResponse.data.data.length} items', 'SyncService');

      // Tipos de Animal
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando tipos de animal...',
        progress: 0.4,
      ));
      
      final tiposAnimalResponse = await ConfigurationService.getTiposAnimal();
      await DatabaseService.saveTiposAnimalOffline(tiposAnimalResponse.data.data);
      LoggingService.info('Tipos de animal synchronized: ${tiposAnimalResponse.data.data.length} items', 'SyncService');

      // Etapas
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando etapas...',
        progress: 0.5,
      ));
      
      final etapas = await ConfigurationService.getEtapas();
      await DatabaseService.saveEtapasOffline(etapas);
      LoggingService.info('Etapas synchronized: ${etapas.length} items', 'SyncService');

      // Fuente Agua
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando fuente de agua...',
        progress: 0.6,
      ));
      
      final fuenteAgua = await ConfigurationService.getFuenteAgua();
      await DatabaseService.saveFuenteAguaOffline(fuenteAgua);
      LoggingService.info('Fuente agua synchronized: ${fuenteAgua.length} items', 'SyncService');

      // Método Riego
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando métodos de riego...',
        progress: 0.65,
      ));
      
      final metodoRiego = await ConfigurationService.getMetodoRiego();
      await DatabaseService.saveMetodoRiegoOffline(metodoRiego);
      LoggingService.info('Método riego synchronized: ${metodoRiego.length} items', 'SyncService');

      // pH Suelo
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando pH de suelo...',
        progress: 0.7,
      ));
      
      final phSuelo = await ConfigurationService.getPhSuelo();
      await DatabaseService.savePhSueloOffline(phSuelo);
      LoggingService.info('pH suelo synchronized: ${phSuelo.length} items', 'SyncService');

      // Sexo
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos de sexo...',
        progress: 0.75,
      ));
      
      final sexo = await ConfigurationService.getSexo();
      await DatabaseService.saveSexoOffline(sexo);
      LoggingService.info('Sexo synchronized: ${sexo.length} items', 'SyncService');

      // Textura Suelo
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando textura de suelo...',
        progress: 0.8,
      ));
      
      final texturaSuelo = await ConfigurationService.getTexturaSuelo();
      await DatabaseService.saveTexturaSueloOffline(texturaSuelo);
      LoggingService.info('Textura suelo synchronized: ${texturaSuelo.length} items', 'SyncService');

      // Tipo Explotación
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando tipos de explotación...',
        progress: 0.85,
      ));
      
      final tipoExplotacion = await ConfigurationService.getTipoExplotacion();
      await DatabaseService.saveTipoExplotacionOffline(tipoExplotacion);
      LoggingService.info('Tipo explotación synchronized: ${tipoExplotacion.length} items', 'SyncService');

      // Tipo Relieve
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando tipos de relieve...',
        progress: 0.9,
      ));
      
      final tipoRelieve = await ConfigurationService.getTipoRelieve();
      await DatabaseService.saveTipoRelieveOffline(tipoRelieve);
      LoggingService.info('Tipo relieve synchronized: ${tipoRelieve.length} items', 'SyncService');

      LoggingService.info('Configuration data synchronization completed successfully', 'SyncService');
    } catch (e) {
      LoggingService.error('Error synchronizing configuration data', 'SyncService', e);
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
      'estado_salud': await DatabaseService.getConfigurationLastUpdated('estado_salud'),
      'tipo_animal': await DatabaseService.getConfigurationLastUpdated('tipo_animal'),
      'etapas': await DatabaseService.getConfigurationLastUpdated('etapa'),
      'fuente_agua': await DatabaseService.getConfigurationLastUpdated('fuente_agua'),
      'metodo_riego': await DatabaseService.getConfigurationLastUpdated('metodo_riego'),
      'ph_suelo': await DatabaseService.getConfigurationLastUpdated('ph_suelo'),
      'sexo': await DatabaseService.getConfigurationLastUpdated('sexo'),
      'textura_suelo': await DatabaseService.getConfigurationLastUpdated('textura_suelo'),
      'tipo_explotacion': await DatabaseService.getConfigurationLastUpdated('tipo_explotacion'),
      'tipo_relieve': await DatabaseService.getConfigurationLastUpdated('tipo_relieve'),
    };
    
    LoggingService.debug('Last sync times retrieved: ${lastSyncTimes.toString()}', 'SyncService');
    return lastSyncTimes;
  }

  static void dispose() {
    LoggingService.debug('Disposing SyncService', 'SyncService');
    _syncController.close();
  }
}