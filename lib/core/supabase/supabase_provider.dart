import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_config.dart';

/// Riverpod provider exposing the Supabase client.
///
/// Throws [StateError] if Supabase has not been initialized.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError(
      'Supabase client is not initialized. '
      'Ensure SupabaseClientService.initialize() is called in main().',
    );
  }
  return client;
});

/// Provider that indicates whether Supabase is configured.
final supabaseConfiguredProvider = Provider<bool>((ref) {
  return SupabaseConfig.isConfigured;
});

/// Provider for the current authenticated user session.
final supabaseSessionProvider = Provider<Session?>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) return null;
  return client.auth.currentSession;
});

/// Provider for the current authenticated user.
final supabaseUserProvider = Provider<User?>((ref) {
  final client = SupabaseClientService.instance.client;
  if (client == null) return null;
  return client.auth.currentUser;
});

/// Wrapper around Supabase Auth operations.
class SupabaseAuth {
  const SupabaseAuth(this._goTrue);

  final GoTrueClient? _goTrue;

  GoTrueClient get _safeClient {
    if (_goTrue == null) {
      throw StateError('Supabase client is not initialized.');
    }
    return _goTrue;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _safeClient.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _safeClient.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _safeClient.signOut();
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) {
    return _safeClient.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }
}

/// Riverpod provider for auth operations.
final supabaseAuthProvider = Provider<SupabaseAuth>((ref) {
  final client = SupabaseClientService.instance.client;
  return SupabaseAuth(client?.auth);
});