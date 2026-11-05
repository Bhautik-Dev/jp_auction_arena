class AppConfig {
  AppConfig._();

  static const String appName = 'JP AUCTION ARENA';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Cricket Auction Management Platform';

  // Environment and runtime flags
  static const bool isDebugBannerEnabled = false;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
