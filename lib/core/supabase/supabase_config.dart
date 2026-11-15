/// Supabase configuration for JP AUCTION ARENA.
///
/// Reads credentials from dart-define environment variables.
/// Defaults are provided for local development; override via --dart-define.
/// NEVER hardcode the service_role / secret key in client code.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL.
  /// Override with: --dart-define=SUPABASE_URL=YOUR_URL
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fxiiivbqrjxdnsvfegvy.supabase.co',
  );

  /// Supabase publishable (anon) key — safe for client-side use.
  /// Override with: --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_dkaOxQ4DvKZnC0T8wIHk4A_1f4kPfnL',
  );

  /// Whether Supabase is properly configured.
  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty;

  /// Validate configuration and throw a clear error if missing.
  static void ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Run with:\n'
        '  flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
      );
    }
  }
}