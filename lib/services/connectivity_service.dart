import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  bool _isOnline = true;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_connectionChanged);
    _checkInitialConnection();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get connectionStream => _connectionChangeController.stream;

  Future<void> _checkInitialConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (_) {
      _isOnline = false;
      _connectionChangeController.add(false);
    }
  }

  void _connectionChanged(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      _isOnline = false;
      _connectionChangeController.add(false);
      return;
    }
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _connectionChangeController.add(hasConnection);
    }
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
