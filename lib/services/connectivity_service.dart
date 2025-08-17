import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamController<bool>? _connectionController;

  static Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    _connectivity.onConnectivityChanged.listen((result) {
      _connectionController!.add(_isConnected(result));
    });
    return _connectionController!.stream;
  }

  static Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  static bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  static void dispose() {
    _connectionController?.close();
    _connectionController = null;
  }
}