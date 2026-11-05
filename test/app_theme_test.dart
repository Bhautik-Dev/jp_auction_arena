import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';

void main() {
  group('AppTheme Color Spec Tests', () {
    test('theme colors match requested specs', () {
      expect(AppColors.background, const Color(0xFF0B1026));
      expect(AppColors.card, const Color(0xFF141B3A));
      expect(AppColors.primaryBlue, const Color(0xFF3B82F6));
      expect(AppColors.secondaryPurple, const Color(0xFF8B5CF6));
      expect(AppColors.accentPink, const Color(0xFFEC4899));
    });

    test('gradient colors match blue -> purple -> pink', () {
      final gradient = AppColors.buttonGradient;
      expect(gradient.colors, [
        AppColors.primaryBlue,
        AppColors.secondaryPurple,
        AppColors.accentPink,
      ]);
    });
  });
}
