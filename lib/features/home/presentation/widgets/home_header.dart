import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/constants/app_dimensions.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceXl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceSm,
                  vertical: AppDimensions.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXs),
                    Text(
                      AppStrings.systemStatusReady,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'v${AppConfig.appVersion}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(
            AppConfig.appName,
            style: theme.textTheme.displayMedium?.copyWith(
              color: isDark ? AppColors.accentLight : AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            AppStrings.appTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            AppStrings.systemStatusDescription,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
