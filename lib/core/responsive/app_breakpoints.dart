abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const wide = 1280.0;

  static bool usesBottomNavigation(double width) => width < compact;

  static bool usesExtendedNavigation(double width) => width >= wide;
}
