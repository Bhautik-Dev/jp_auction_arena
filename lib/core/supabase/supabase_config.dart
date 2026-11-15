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

  // -------------------------------------------------------------------------
  // SMTP / Email Configuration
  // -------------------------------------------------------------------------
  //
  // These values are NOT used by the Flutter client directly. Supabase Auth
  // emails (confirmation, password reset) are sent by Supabase's email
  // service using SMTP settings configured in the Supabase Dashboard:
  //   Authentication → Email Templates → SMTP Settings
  //
  // These fields document the required SMTP settings for reference and for
  // any future server-side SMTP integration.
  //
  // To fix email rate limits:
  //   1. Disable email confirmation: Auth → Settings → "Enable email
  //      confirmations" = OFF
  //   2. Configure custom SMTP: Auth → Email Templates → SMTP Settings
  //      with your own SMTP server (SendGrid, Mailgun, AWS SES, etc.)
  // -------------------------------------------------------------------------

  /// SMTP host (e.g. smtp.sendgrid.net, smtp.mailgun.org)
  static const String smtpHost = String.fromEnvironment(
    'SMTP_HOST',
    defaultValue: '',
  );

  /// SMTP port (e.g. 587, 465, 2525)
  static const int smtpPort = int.fromEnvironment(
    'SMTP_PORT',
    defaultValue: 587,
  );

  /// SMTP username
  static const String smtpUser = String.fromEnvironment(
    'SMTP_USER',
    defaultValue: '',
  );

  /// SMTP password / API key
  static const String smtpPass = String.fromEnvironment(
    'SMTP_PASS',
    defaultValue: '',
  );

  /// Sender email address (must be verified with your SMTP provider)
  static const String smtpFrom = String.fromEnvironment(
    'SMTP_FROM',
    defaultValue: '',
  );

  /// Sender name
  static const String smtpFromName = String.fromEnvironment(
    'SMTP_FROM_NAME',
    defaultValue: 'JP Auction Arena',
  );

  /// Whether custom SMTP is configured.
  static bool get smtpConfigured =>
      smtpHost.isNotEmpty &&
      smtpUser.isNotEmpty &&
      smtpPass.isNotEmpty &&
      smtpFrom.isNotEmpty;
}
