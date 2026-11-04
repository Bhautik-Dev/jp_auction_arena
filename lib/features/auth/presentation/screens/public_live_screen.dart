import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';

class PublicLiveScreen extends ConsumerWidget {
  const PublicLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (session) => session != null);
    return Scaffold(
      appBar: AppBar(
        leading: isAuthenticated == true
            ? IconButton(
                tooltip: 'Back to dashboard',
                onPressed: () => context.go(RouteNames.dashboard),
                icon: const Icon(Icons.dashboard_outlined),
              )
            : null,
        title: const Text('Public Live Auction'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Public view',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Only approved public auction information is shown here. '
                    'Live auction data is not connected yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
