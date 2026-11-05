import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('lightTheme has correct brightness and primary color', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme has correct brightness and primary color', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primaryLight);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
