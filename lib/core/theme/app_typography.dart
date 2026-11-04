import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const _font = 'Roboto';

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _font,
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
    ),
    headlineLarge: TextStyle(
      fontFamily: _font,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: _font,
      fontSize: 26,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: _font,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontFamily: _font, fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontFamily: _font, fontSize: 14, height: 1.5),
    labelLarge: TextStyle(
      fontFamily: _font,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}
