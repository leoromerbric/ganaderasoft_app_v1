import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamController<bool>? _connectionController;

  static Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _connectionController!.add(_isConnected(results.isNotEmpty ? results.first : ConnectivityResult.none));
    });
    return _connectionController!.stream;
  }

  static Future<bool> isConnected() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return _isConnected(results.isNotEmpty ? results.first : ConnectivityResult.none);
  }

  static bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  static void dispose() {
    _connectionController?.close();
    _connectionController = null;
  }
}