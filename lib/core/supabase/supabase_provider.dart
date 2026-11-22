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
