import 'dart:async';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class OfflineManager {
  static StreamSubscription<bool>? _connectivitySubscription;
  static bool _wasOffline = false;

  static void startMonitoring() {
    LoggingService.info('Starting offline monitoring...', 'OfflineManager');

    _connectivitySubscription = ConnectivityService.connectionStream.listen((
      isConnected,
    ) {
      LoggingService.debug(
        'Connectivity changed: $isConnected',
        'OfflineManager',
      );

      if (!isConnected) {
        if (!_wasOffline) {
          LoggingService.info('Device went offline', 'OfflineManager');
        }
        _wasOffline = true;
      } else if (_wasOffline) {
        // Came back online - log but don't auto-sync per requirements
        LoggingService.info(
          'Device came back online - auto-sync disabled per requirements',
          'OfflineManager',
        );
        _wasOffline = false;
        // Auto-sync disabled: _autoSync();
        // All synchronization must be manually triggered via "Sincronizar cambios" button
      }
    });
  }

  static void stopMonitoring() {
    LoggingService.info('Stopping offline monitoring', 'OfflineManager');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
