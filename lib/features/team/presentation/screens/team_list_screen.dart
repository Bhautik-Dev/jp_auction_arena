import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/core/responsive/responsive_content.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_filter_bar.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_logo_view.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_status_badge.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamListProvider);
    final tournamentsAsync = ref.watch(tournamentListProvider);
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: AppColors.neonPink),
            SizedBox(width: 10),
            Text('Teams'),
          ],
        ),
        actions: [
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/teams/create'),
                icon: const Icon(Icons.add),
                label: const Text('New Team'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teams/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
      ),
      body: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tournamentsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => _InlineError(
                message: 'Failed to load tournaments: $error',
                onRetry: () => ref.invalidate(tournamentListProvider),
              ),
              data: (tournaments) => TeamFilterBar(tournaments: tournaments),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tournamentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _InlineError(
                  message: 'Failed to load tournaments: $error',
                  onRetry: () => ref.invalidate(tournamentListProvider),
                ),
                data: (tournaments) {
                  if (tournaments.isEmpty) {
                    return const _EmptyState(
                      title: 'Create a tournament first',
                      message:
                          'Every team must belong to a tournament. Create a '
                          'tournament before registering teams.',
                    );
                  }
                  return teamsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _InlineError(
                      message: 'Failed to load teams: $error',
                      onRetry: () =>
                          ref.read(teamListProvider.notifier).refresh(),
                    ),
                    data: (teams) => teams.isEmpty
                        ? const _EmptyState(
                            title: 'No teams found',
                            message:
                                'Try changing your search or filters, or create '
                                'a team for a tournament.',
                          )
                        : _TeamGrid(
                            teams: teams,
                            tournaments: tournaments,
                            onDelete: (team) =>
                                _confirmDelete(context, ref, team),
                            onStatusChange: (team, status) =>
                                _changeStatus(context, ref, team, status),
                            onRefresh: () =>
                                ref.read(teamListProvider.notifier).refresh(),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Team team,
    TeamStatus status,
  ) async {
    try {
      await ref.read(teamListProvider.notifier).changeStatus(team.id, status);
      if (context.mounted) {
        _showMessage(context, '${team.name} is now ${status.label}.');
      }
    } on TeamException catch (error) {
      if (context.mounted) _showMessage(context, error.message, isError: true);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    if (!team.canDelete) {
      final deactivate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Team cannot be deleted'),
          content: Text(
            '${team.deletionBlockReason} Deactivate or archive the team '
            'instead to preserve its history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate team'),
            ),
          ],
        ),
      );
      if (deactivate == true && context.mounted) {
        await _changeStatus(context, ref, team, TeamStatus.inactive);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team?'),
        content: Text(
          'Delete "${team.name}"? This removes the team from the in-memory '
          'team list and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(teamListProvider.notifier).deleteTeam(team.id);
      if (context.mounted) _showMessage(context, '${team.name} deleted.');
    } on TeamException catch (error) {
      if (context.mounted) _showMessage(context, error.message, isError: true);
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }
}

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({
    required this.teams,
    required this.tournaments,
    required this.onDelete,
    required this.onStatusChange,
    required this.onRefresh,
  });

  final List<Team> teams;
  final List<Tournament> tournaments;
  final ValueChanged<Team> onDelete;
  final void Function(Team, TeamStatus) onStatusChange;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 176,
            ),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final tournament = _tournamentFor(team, tournaments);
              return _TeamCard(
                team: team,
                tournamentName: tournament?.name ?? 'Tournament unavailable',
                onDelete: () => onDelete(team),
                onStatusChange: (status) => onStatusChange(team, status),
              );
            },
          ),
        );
      },
    );
  }

  Tournament? _tournamentFor(Team team, List<Tournament> tournaments) {
    for (final tournament in tournaments) {
      if (tournament.id == team.tournamentId) return tournament;
    }
    return null;
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.tournamentName,
    required this.onDelete,
    required this.onStatusChange,
  });

  final Team team;
  final String tournamentName;
  final VoidCallback onDelete;
  final ValueChanged<TeamStatus> onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/teams/${team.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TeamLogoView(team: team, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          team.shortName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Team actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          context.push('/teams/${team.id}/edit');
                        case 'activate':
                          onStatusChange(TeamStatus.active);
                        case 'deactivate':
                          onStatusChange(TeamStatus.inactive);
                        case 'archive':
                          onStatusChange(TeamStatus.archived);
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit team'),
                      ),
                      if (team.status != TeamStatus.active)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Text('Activate'),
                        ),
                      if (team.status == TeamStatus.active)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Deactivate'),
                        ),
                      if (team.status != TeamStatus.archived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Archive'),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                tournamentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TeamStatusBadge(status: team.status)),
                  _ColorDot(colorValue: team.primaryColorValue),
                  const SizedBox(width: 6),
                  _ColorDot(colorValue: team.secondaryColorValue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.colorValue});

  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 52,
              color: AppColors.neonPink,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(message)),
        IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
      ],
    );
  }
}
