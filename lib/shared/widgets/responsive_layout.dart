import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_dimensions.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.breakpointMobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppDimensions.breakpointMobile &&
        width < AppDimensions.breakpointTablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.breakpointTablet) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppDimensions.breakpointMobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
