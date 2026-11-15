import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_config.dart';

/// Global Supabase client accessor.
///
/// Throws [StateError] if accessed before [SupabaseClientService.initialize] is called.
SupabaseClient get supabaseClient {
  final client = SupabaseClientService.instance.client;
  if (client == null) {
    throw StateError(
      'Supabase client is not initialized. Call SupabaseClientService.initialize() first.',
    );
  }
  return client;
}

/// Service responsible for initializing and holding the Supabase client.
class SupabaseClientService {
  SupabaseClientService._();

  static SupabaseClientService? _instance;

  /// The initialized Supabase client instance.
  SupabaseClient? client;

  /// Whether initialization has completed successfully.
  bool get isInitialized => client != null;

  /// Get the singleton service instance.
  static SupabaseClientService get instance => _instance ??= SupabaseClientService._();

  /// Initialize Supabase for both Web and Android.
  ///
  /// Must be called inside [main()] before [runApp].
  /// Throws [StateError] if credentials are missing.
  static Future<void> initialize() async {
    SupabaseConfig.ensureConfigured();

    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
      debug: kDebugMode,
    );

    instance.client = Supabase.instance.client;
  }
}