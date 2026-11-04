import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen> {
  TournamentStatus? _status;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: _buildContent(context)));

  Widget _buildContent(BuildContext context) {
    final tournaments = ref.watch(tournamentsProvider);
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tournaments',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New Tournament'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _filterChip('All', null),
            for (final status in TournamentStatus.values)
              _filterChip(status.label, status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        tournaments.when(
          loading: () =>
              const SizedBox(height: 240, child: AppLoadingIndicator()),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(tournamentsProvider),
          ),
          data: (items) {
            final visible = _status == null
                ? items
                : items.where((item) => item.status == _status).toList();
            if (visible.isEmpty) {
              return const SizedBox(
                height: 240,
                child: AppEmptyState(title: 'No tournaments found'),
              );
            }
            return Column(
              children: [
                for (final tournament in visible) ...[
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${tournament.city} | ${tournament.seasonYear}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Chip(label: Text(tournament.status.label)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, TournamentStatus? status) => FilterChip(
    label: Text(label),
    selected: _status == status,
    onSelected: (_) => setState(() => _status = status),
  );
}
