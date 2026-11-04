import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Teams',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ref
              .watch(teamsProvider)
              .when(
                loading: () =>
                    const SizedBox(height: 220, child: AppLoadingIndicator()),
                error: (error, stackTrace) => AppErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(teamsProvider),
                ),
                data: (teams) => Column(
                  children: [
                    for (final team in teams) ...[
                      AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Color(team.primaryColorValue),
                            child: Text(team.shortName),
                          ),
                          title: Text(team.name),
                          subtitle: Text('Owner: ${team.ownerName}'),
                          trailing: Text(team.status.label),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}
