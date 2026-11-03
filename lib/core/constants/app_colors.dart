import 'package:flutter/material.dart';

/// Central color tokens for the JP AUCTION ARENA brand.
class AppColors {
  AppColors._();

  static const Color deepNavy = Color(0xFF080A1D);
  static const Color darkPurple = Color(0xFF121028);
  static const Color softPurple = Color(0xFF211B3D);
  static const Color raisedPurple = Color(0xFF2D254B);

  static const Color electricBlue = Color(0xFF2A63DD);
  static const Color actionBlue = Color(0xFF1F4FCB);
  static const Color neonPink = Color(0xFFFF4FA8);
  static const Color actionPink = Color(0xFFC21870);
  static const Color magenta = Color(0xFFD946EF);
  static const Color white = Color(0xFFFFFFFF);

  static const Color lightBackground = Color(0xFFF6F4FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFEDE9F7);
  static const Color lightPurpleContainer = Color(0xFFE9E2F5);
  static const Color lightCardBorder = Color(0xFFE1DCEF);
  static const Color lightTextPrimary = Color(0xFF17132B);
  static const Color lightTextSecondary = Color(0xFF5C5673);

  static const Color darkBackground = deepNavy;
  static const Color darkSurface = darkPurple;
  static const Color darkSurfaceContainer = softPurple;
  static const Color darkCardBorder = raisedPurple;
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = Color(0xFFB8B1D0);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color muted = Color(0xFF77718D);

  // Keep the existing tournament feature on the shared brand palette.
  static const Color primaryDarkBlue = deepNavy;
  static const Color primaryNavy = actionBlue;
  static const Color primaryBlueAccent = actionBlue;
  static const Color lightBlueAccent = electricBlue;
  static const Color goldAccent = neonPink;
  static const Color amberAccent = magenta;
}
