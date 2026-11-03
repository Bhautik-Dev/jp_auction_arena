/// Shared width thresholds for responsive application layouts.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double extendedNavigation = 1280;
  static const double contentMaxWidth = 1120;

  static bool usesBottomNavigation(double width) => width < compact;

  static bool usesExtendedNavigation(double width) =>
      width >= extendedNavigation;
}
