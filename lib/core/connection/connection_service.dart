import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connection status for the app.
enum ConnectionStatus {
  wifi('WiFi'),
  mobile('Mobile'),
  none('Offline'),
  unknown('Unknown');

  const ConnectionStatus(this.label);

  final String label;
}

/// Service that exposes the device's current network connection as a Riverpod
/// stream. Used by the AppBar to show an online/offline indicator.
class ConnectionService {
  ConnectionService._();

  static final ConnectionService _instance = ConnectionService._();

  /// Singleton accessor.
  static ConnectionService get instance => _instance;

  final Connectivity _connectivity = Connectivity();

  /// Current connection status (synchronous snapshot).
  ConnectionStatus get currentStatus => _status;

  ConnectionStatus _status = ConnectionStatus.none;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get statusStream =>
      _connectivity.onConnectivityChanged.map(_mapResults).distinct();

  /// Initialize the service and emit an initial status.
  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _status = _mapResults(result);
  }

  /// Refresh the cached status once.
  Future<ConnectionStatus> refresh() async {
    final result = await _connectivity.checkConnectivity();
    _status = _mapResults(result);
    return _status;
  }

  /// Map a list of [ConnectivityResult] entries to a [ConnectionStatus].
  ConnectionStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return ConnectionStatus.none;
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      return ConnectionStatus.wifi;
    }
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.bluetooth)) {
      return ConnectionStatus.mobile;
    }
    if (results.contains(ConnectivityResult.satellite)) {
      return ConnectionStatus.wifi;
    }
    if (results.contains(ConnectivityResult.other)) {
      return ConnectionStatus.unknown;
    }
    return ConnectionStatus.none;
  }
}

/// Riverpod provider exposing the current [ConnectionStatus].
final connectionStatusProvider =
    StreamProvider<ConnectionStatus>((ref) async* {
  final service = ConnectionService.instance;
  // Emit the cached snapshot first so the UI updates immediately.
  yield service.currentStatus;
  yield* service.statusStream;
});

/// Convenience provider returning a synchronous snapshot of the status.
final currentConnectionStatusProvider = Provider<ConnectionStatus>((ref) {
  return ConnectionService.instance.currentStatus;
});