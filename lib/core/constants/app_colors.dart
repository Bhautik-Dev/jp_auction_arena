import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Requested Theme Colors
  static const Color background = Color(0xFF0B1026); // Dark navy background
  static const Color backgroundLight = Color(0xFF0B1026); // Default dark theme
  static const Color backgroundDark = Color(0xFF0B1026);

  static const Color card = Color(0xFF141B3A); // Card color with glass effect
  static const Color cardBorder = Color(0x338B5CF6); // Soft purple-tinted border
  static const Color cardBorderHover = Color(0x668B5CF6);

  // Gradient & Accent Colors
  static const Color primaryBlue = Color(0xFF3B82F6); // Primary blue
  static const Color secondaryPurple = Color(0xFF8B5CF6); // Secondary purple
  static const Color accentPink = Color(0xFFEC4899); // Accent pink

  // Gradients
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple, accentPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xEE141B3A),
      Color(0xCC18224B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surfaces & Overlays
  static const Color surface = Color(0xFF141B3A);
  static const Color surfaceLight = Color(0xFF1E2852);
  static const Color surfaceHighlight = Color(0xFF243063);
  static const Color overlayGlass = Color(0x1AFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color gold = Color(0xFFFFD700);

  // Status badges
  static const Color statusLive = Color(0xFFEF4444);
  static const Color statusSold = Color(0xFF10B981);
  static const Color statusUnsold = Color(0xFF64748B);
  static const Color statusAvailable = Color(0xFF3B82F6);
}
