import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/responsive_content.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_logo_view.dart';
import 'package:jp_auction_arena/features/team/presentation/widgets/team_status_badge.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(singleTeamProvider(teamId));
    final tournamentsAsync = ref.watch(tournamentListProvider);
    final team = teamAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team details'),
        actions: [
          IconButton(
            tooltip: 'Edit team',
            onPressed: () => context.push('/teams/$teamId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Team actions',
            onSelected: (value) => _handleAction(context, ref, value),
            itemBuilder: (context) => [
              if (team?.status != TeamStatus.active)
                const PopupMenuItem(
                  value: 'activate',
                  child: Text('Activate team'),
                ),
              if (team?.status == TeamStatus.active)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate team'),
                ),
              if (team?.status != TeamStatus.archived)
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive team'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Text('Delete team')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _Message(message: 'Failed to load team: $error'),
        data: (team) {
          if (team == null) return const _Message(message: 'Team not found.');
          return tournamentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _Message(message: 'Failed to load tournament: $error'),
            data: (tournaments) {
              String tournamentName = 'Tournament unavailable';
              for (final tournament in tournaments) {
                if (tournament.id == team.tournamentId) {
                  tournamentName = tournament.name;
                  break;
                }
              }
              return _TeamDetails(team: team, tournamentName: tournamentName);
            },
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final team = await ref.read(teamRepositoryProvider).getTeamById(teamId);
    if (team == null || !context.mounted) return;

    switch (action) {
      case 'activate':
        await _changeStatus(context, ref, TeamStatus.active);
        return;
      case 'deactivate':
        await _changeStatus(context, ref, TeamStatus.inactive);
        return;
      case 'archive':
        await _changeStatus(context, ref, TeamStatus.archived);
        return;
      case 'delete':
        await _delete(context, ref, team);
        return;
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    TeamStatus status,
  ) async {
    try {
      await ref.read(teamListProvider.notifier).changeStatus(teamId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team ${status.label.toLowerCase()}.')),
        );
      }
    } on TeamException catch (error) {
      if (context.mounted) _showError(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Team team) async {
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
        await _changeStatus(context, ref, TeamStatus.inactive);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team?'),
        content: Text('Delete "${team.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(teamListProvider.notifier).deleteTeam(team.id);
      if (context.mounted) context.go('/teams');
    } on TeamException catch (error) {
      if (context.mounted) _showError(context, error.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }
}

class _TeamDetails extends StatelessWidget {
  const _TeamDetails({required this.team, required this.tournamentName});

  final Team team;
  final String tournamentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    TeamLogoView(team: team, size: 76),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team.name, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            team.shortName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TeamStatusBadge(status: team.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailsCard(
              title: 'Tournament',
              icon: Icons.emoji_events_outlined,
              rows: {'Tournament': tournamentName},
            ),
            const SizedBox(height: 16),
            _DetailsCard(
              title: 'Team contacts',
              icon: Icons.contact_mail_outlined,
              rows: {
                'Owner': team.ownerName,
                'Manager': team.managerName,
                'Email': team.contactEmail,
                'Phone': team.contactPhone,
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team colors', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _ColorRow(
                      label: 'Primary',
                      colorValue: team.primaryColorValue,
                    ),
                    const SizedBox(height: 10),
                    _ColorRow(
                      label: 'Secondary',
                      colorValue: team.secondaryColorValue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in rows.entries) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(entry.value)),
                ],
              ),
              if (entry.key != rows.keys.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.colorValue});

  final String label;
  final int colorValue;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 10),
        Text(label),
        const Spacer(),
        Text('#${colorValue.toRadixString(16).substring(2).toUpperCase()}'),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
