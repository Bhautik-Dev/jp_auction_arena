import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_strings.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(
        AppStrings.appName,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        AppStrings.welcomeTitle,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Your tournament and auction workspace.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.tertiary,
              size: 30,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your platform foundation is ready',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Shared navigation, responsive layouts, and the JP AUCTION '
              'ARENA design system are in place. Tournament and auction '
              'modules will be added in approved future phases.',
            ),
          ],
        ),
      ),
    ],
  );
}
