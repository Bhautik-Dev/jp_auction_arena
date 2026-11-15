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
  Stream<ConnectionStatus> get statusStream => _connectivity.onConnectivityChanged
      .asyncMap(_mapConnectivity)
      .distinct();

  /// Initialize the service and emit an initial status.
  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _status = _mapConnectivity(result);
  }

  /// Refresh the cached status once.
  Future<ConnectionStatus> refresh() async {
    final result = await _connectivity.checkConnectivity();
    _status = _mapConnectivity(result);
    return _status;
  }

  /// Map a [ConnectivityResult] to a [ConnectionStatus].
  ConnectionStatus _mapConnectivity(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => ConnectionStatus.wifi,
      ConnectivityResult.mobile => ConnectionStatus.mobile,
      ConnectivityResult.none => ConnectionStatus.none,
      ConnectivityResult.ethernet => ConnectionStatus.wifi,
      ConnectivityResult.bluetooth => ConnectionStatus.mobile,
      ConnectivityResult.vpn => ConnectionStatus.wifi,
      ConnectivityResult.other => ConnectionStatus.unknown,
    };
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