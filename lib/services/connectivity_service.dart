import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'logging_service.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamController<bool>? _connectionController;
  static const Duration _serverCheckTimeout = Duration(seconds: 5);

  static Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) async {
      final hasNetwork = _hasNetworkConnection(result);
      if (hasNetwork) {
        // Only check server reachability if we have network
        final isServerReachable = await _isServerReachable();
        _connectionController!.add(isServerReachable);
      } else {
        // No network, definitely not connected
        _connectionController!.add(false);
      }
    });
    return _connectionController!.stream;
  }

  /// Checks both network connectivity and server reachability
  static Future<bool> isConnected() async {
    try {
      LoggingService.debug('Checking connectivity...', 'ConnectivityService');

      // First check if we have network connectivity
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      final hasNetwork = _hasNetworkConnection(result);

      if (!hasNetwork) {
        LoggingService.debug(
          'No network connectivity detected',
          'ConnectivityService',
        );
        return false;
      }

      LoggingService.debug(
        'Network connectivity detected, checking server reachability...',
        'ConnectivityService',
      );

      // Then check if server is reachable
      final isServerReachable = await _isServerReachable();
      LoggingService.debug(
        'Server reachable: $isServerReachable',
        'ConnectivityService',
      );

      return isServerReachable;
    } catch (e) {
      LoggingService.error(
        'Error checking connectivity',
        'ConnectivityService',
        e,
      );
      return false;
    }
  }

  /// Checks only network connectivity (without server reachability)
  static Future<bool> hasNetworkConnection() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    return _hasNetworkConnection(result);
  }

  static bool _hasNetworkConnection(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Checks if the server is actually reachable by making a quick HTTP request
  static Future<bool> _isServerReachable() async {
    try {
      LoggingService.debug(
        'Pinging server at ${AppConfig.baseUrl}...',
        'ConnectivityService',
      );

      // Try to reach the server with a short timeout
      final response = await http
          .head(
            Uri.parse(AppConfig.apiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_serverCheckTimeout);

      // Accept any response from the server (even 404, as long as server responds)
      final isReachable = response.statusCode < 1000;
      LoggingService.debug(
        'Server ping result: ${response.statusCode} (reachable: $isReachable)',
        'ConnectivityService',
      );

      return isReachable;
    } on TimeoutException {
      LoggingService.warning('Server ping timeout', 'ConnectivityService');
      return false;
    } on SocketException catch (e) {
      LoggingService.warning(
        'Server ping socket error: ${e.message}',
        'ConnectivityService',
      );
      return false;
    } catch (e) {
      LoggingService.warning('Server ping error: $e', 'ConnectivityService');
      return false;
    }
  }

  static void dispose() {
    _connectionController?.close();
    _connectionController = null;
  }
}
