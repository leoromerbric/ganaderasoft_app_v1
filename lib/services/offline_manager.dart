import 'dart:async';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class OfflineManager {
  static StreamSubscription<bool>? _connectivitySubscription;
  static bool _wasOffline = false;

  static void startMonitoring() {
    _connectivitySubscription = ConnectivityService.connectionStream.listen((isConnected) {
      if (!isConnected) {
        _wasOffline = true;
      } else if (_wasOffline) {
        // Came back online, trigger sync
        _wasOffline = false;
        _autoSync();
      }
    });
  }

  static void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  static Future<void> _autoSync() async {
    // Auto-sync in background when coming back online
    try {
      await SyncService.syncData();
    } catch (e) {
      // Silent failure for auto-sync
      print('Auto-sync failed: $e');
    }
  }
}