import 'dart:async';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../models/user.dart';
import '../models/finca.dart';

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
    try {
      // Check connectivity
      if (!await ConnectivityService.isConnected()) {
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'No hay conexión a internet',
        ));
        return false;
      }

      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Iniciando sincronización...',
        progress: 0.1,
      ));

      // Sync user data
      _syncController.add(SyncData(
        status: SyncStatus.syncing,
        message: 'Sincronizando datos del usuario...',
        progress: 0.3,
      ));

      try {
        final user = await _authService.getProfile();
        await DatabaseService.saveUserOffline(user);
        await _authService.saveUser(user);
      } catch (e) {
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
        progress: 0.7,
      ));

      try {
        final fincasResponse = await _authService.getFincas();
        await DatabaseService.saveFincasOffline(fincasResponse.fincas);
      } catch (e) {
        _syncController.add(SyncData(
          status: SyncStatus.error,
          message: 'Error al sincronizar fincas: ${e.toString()}',
        ));
        return false;
      }

      _syncController.add(SyncData(
        status: SyncStatus.success,
        message: 'Sincronización completada exitosamente',
        progress: 1.0,
      ));

      return true;
    } catch (e) {
      _syncController.add(SyncData(
        status: SyncStatus.error,
        message: 'Error inesperado: ${e.toString()}',
      ));
      return false;
    }
  }

  static Future<Map<String, DateTime?>> getLastSyncTimes() async {
    return {
      'user': await DatabaseService.getUserLastUpdated(),
      'fincas': await DatabaseService.getFincasLastUpdated(),
    };
  }

  static void dispose() {
    _syncController.close();
  }
}