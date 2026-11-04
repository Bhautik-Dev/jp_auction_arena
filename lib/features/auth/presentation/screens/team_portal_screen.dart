import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';

class TeamPortalScreen extends ConsumerWidget {
  const TeamPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (value) => value);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your team workspace',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Signed in as ${session?.user.displayName ?? ''}.'),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'This role can only view its assigned team. Team purse, '
                'squad, and live auction data are not connected in this '
                'authentication foundation.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
