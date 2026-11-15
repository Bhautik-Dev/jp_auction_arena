import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of a single Supabase sync operation.
class SupabaseSyncResult {
  const SupabaseSyncResult({
    required this.table,
    required this.op,
    required this.success,
    this.error,
  });

  final String table;
  final String op;
  final bool success;
  final String? error;
}

/// State tracked by [SupabaseSyncNotifier].
class SupabaseSyncState {
  const SupabaseSyncState({
    this.lastResult,
    this.lastError,
    this.lastSuccess,
    this.isConnected = false,
  });

  final SupabaseSyncResult? lastResult;
  final String? lastError;
  final SupabaseSyncResult? lastSuccess;
  final bool isConnected;

  SupabaseSyncState copyWith({
    SupabaseSyncResult? lastResult,
    String? lastError,
    SupabaseSyncResult? lastSuccess,
    bool? isConnected,
  }) {
    return SupabaseSyncState(
      lastResult: lastResult ?? this.lastResult,
      lastError: lastError ?? this.lastError,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Notifier that tracks the latest Supabase sync result.
class SupabaseSyncNotifier extends Notifier<SupabaseSyncState> {
  @override
  SupabaseSyncState build() {
    return const SupabaseSyncState(isConnected: false);
  }

  void recordSuccess(SupabaseSyncResult result) {
    state = state.copyWith(
      lastResult: result,
      lastSuccess: result,
      lastError: null,
    );
  }

  void recordError(SupabaseSyncResult result) {
    state = state.copyWith(
      lastResult: result,
      lastError: result.error,
    );
  }

  void setConnected(bool connected) {
    state = state.copyWith(isConnected: connected);
  }
}

/// Riverpod provider exposing the latest Supabase sync status.
final supabaseSyncNotifierProvider =
    NotifierProvider<SupabaseSyncNotifier, SupabaseSyncState>(
  SupabaseSyncNotifier.new,
);
