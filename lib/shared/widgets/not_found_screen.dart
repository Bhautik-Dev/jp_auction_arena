import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_dimensions.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notFoundTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 72,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text(
                AppStrings.notFoundTitle,
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                AppStrings.notFoundMessage,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceXl),
              AppButton(
                label: AppStrings.goHome,
                width: 180,
                onPressed: () => context.go(RouteNames.homePath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
