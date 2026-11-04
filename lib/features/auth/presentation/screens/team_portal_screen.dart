import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_purse_squad_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_purse_squad_panel.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TeamPortalScreen extends ConsumerWidget {
  const TeamPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (value) => value);
    final snapshots = ref.watch(assignedTeamPurseSquadsProvider);
    return snapshots.when(
      loading: () => const AppLoadingIndicator(
        label: 'Loading your team purse and squad...',
      ),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(assignedTeamPurseSquadsProvider),
      ),
      data: (teams) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your team workspace',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Signed in as ${session?.user.displayName ?? ''}.'),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Purse and squad information is read-only. Player purchases '
                      'and purse deductions are not enabled in this phase.',
                    ),
                  ],
                ),
              ),
              if (teams.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: AppCard(
                    child: Text(
                      'No auction team is currently assigned to your account.',
                    ),
                  ),
                )
              else
                for (final snapshot in teams)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: AppCard(
                      child: TeamPurseSquadPanel(
                        snapshot: snapshot,
                        canAdjustPurse: false,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
