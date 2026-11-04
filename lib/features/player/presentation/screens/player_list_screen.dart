import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/core/responsive/responsive_content.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_avatar.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_filter_bar.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_status_badge.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';

class PlayerListScreen extends ConsumerWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playerListProvider);
    final teamsAsync = ref.watch(teamsForPlayerAssignmentProvider);
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people_alt_outlined, color: AppColors.neonPink),
            SizedBox(width: 10),
            Text('Players'),
          ],
        ),
        actions: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/players/create'),
                icon: const Icon(Icons.add),
                label: const Text('New Player'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/players/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Player'),
      ),
      body: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PlayerFilterBar(),
            const SizedBox(height: 20),
            Expanded(
              child: playersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _PlayerError(
                  message: 'Failed to load players: $error',
                  onRetry: () =>
                      ref.read(playerListProvider.notifier).refresh(),
                ),
                data: (players) {
                  if (players.isEmpty) {
                    return const _PlayerEmptyState();
                  }
                  final teams = teamsAsync.asData?.value ?? const <Team>[];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 920
                          ? 3
                          : constraints.maxWidth >= 580
                          ? 2
                          : 1;
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(playerListProvider.notifier).refresh(),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 176,
                              ),
                          itemCount: players.length,
                          itemBuilder: (context, index) => _PlayerCard(
                            player: players[index],
                            teamName: _teamName(players[index], teams),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _teamName(Player player, List<Team> teams) {
    if (player.assignedTeamId == null) return 'No team assigned';
    for (final team in teams) {
      if (team.id == player.assignedTeamId) return team.name;
    }
    return 'Assigned team unavailable';
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.teamName});

  final Player player;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/players/${player.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerAvatar(player: player),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          player.category.label,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PlayerStatusBadge(status: player.status),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 18,
                    color: AppColors.neonPink,
                  ),
                  Text(
                    '${_price(player.basePrice)} base price',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    teamName == 'No team assigned'
                        ? Icons.groups_outlined
                        : Icons.groups,
                    size: 17,
                    color: AppColors.electricBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerEmptyState extends StatelessWidget {
  const _PlayerEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_search_outlined,
            size: 56,
            color: AppColors.magenta,
          ),
          const SizedBox(height: 12),
          Text(
            'No players found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('Try another search or filter, or add a player.'),
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _price(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (match) => ',',
);
