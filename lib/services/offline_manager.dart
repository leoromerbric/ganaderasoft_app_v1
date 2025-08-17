import 'dart:async';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/logging_service.dart';

class OfflineManager {
  static StreamSubscription<bool>? _connectivitySubscription;
  static bool _wasOffline = false;

  static void startMonitoring() {
    LoggingService.info('Starting offline monitoring...', 'OfflineManager');
    
    _connectivitySubscription = ConnectivityService.connectionStream.listen((isConnected) {
      LoggingService.debug('Connectivity changed: $isConnected', 'OfflineManager');
      
      if (!isConnected) {
        if (!_wasOffline) {
          LoggingService.info('Device went offline', 'OfflineManager');
        }
        _wasOffline = true;
      } else if (_wasOffline) {
        // Came back online, trigger sync
        LoggingService.info('Device came back online - triggering auto-sync', 'OfflineManager');
        _wasOffline = false;
        _autoSync();
      }
    });
  }

  static void stopMonitoring() {
    LoggingService.info('Stopping offline monitoring', 'OfflineManager');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  static Future<void> _autoSync() async {
    // Auto-sync in background when coming back online
    try {
      LoggingService.info('Starting auto-sync after connectivity restored', 'OfflineManager');
      await SyncService.syncData();
      LoggingService.info('Auto-sync completed successfully', 'OfflineManager');
    } catch (e) {
      // Silent failure for auto-sync
      LoggingService.warning('Auto-sync failed: $e', 'OfflineManager');
    }
  }
}