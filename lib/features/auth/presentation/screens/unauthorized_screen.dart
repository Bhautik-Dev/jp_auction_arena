import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 52,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Access not allowed',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your account does not have permission to open this page.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Continue',
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go(RouteAccessPolicy.login);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
