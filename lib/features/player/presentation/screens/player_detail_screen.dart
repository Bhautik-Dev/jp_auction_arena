import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/responsive_content.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_avatar.dart';
import 'package:jp_auction_arena/features/player/presentation/widgets/player_status_badge.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({required this.playerId, super.key});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(singlePlayerProvider(playerId));
    final teamsAsync = ref.watch(teamsForPlayerAssignmentProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player details'),
        actions: [
          IconButton(
            tooltip: 'Edit player',
            onPressed: () => context.push('/players/$playerId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete player',
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: playerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _Message(message: 'Failed to load player: $error'),
        data: (player) {
          if (player == null) {
            return const _Message(message: 'Player not found.');
          }
          return teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _Message(message: 'Failed to load assigned team: $error'),
            data: (teams) =>
                _Details(player: player, teamName: _teamName(player, teams)),
          );
        },
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final player = await ref
        .read(playerRepositoryProvider)
        .getPlayerById(playerId);
    if (player == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete player?'),
        content: Text('Delete "${player.name}"? This cannot be undone.'),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(playerListProvider.notifier).deletePlayer(playerId);
      if (context.mounted) context.go('/players');
    } on PlayerException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.player, required this.teamName});

  final Player player;
  final String? teamName;

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
                    PlayerAvatar(player: player, size: 76),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            player.category.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.electricBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PlayerStatusBadge(status: player.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player information',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.currency_rupee,
                      label: 'Base price',
                      value: '₹ ${_formatPrice(player.basePrice)}',
                    ),
                    _DetailRow(
                      icon: Icons.sports_cricket_outlined,
                      label: 'Batting style',
                      value: _valueOrNotSpecified(player.battingStyle),
                    ),
                    _DetailRow(
                      icon: Icons.sports_baseball_outlined,
                      label: 'Bowling style',
                      value: _valueOrNotSpecified(player.bowlingStyle),
                    ),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact number',
                      value: player.contactNumber ?? 'Not provided',
                    ),
                    _DetailRow(
                      icon: Icons.groups_outlined,
                      label: 'Assigned team',
                      value: teamName ?? 'No team assigned',
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.magenta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profile photo upload is not available yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
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

  String _valueOrNotSpecified(String value) =>
      value.trim().isEmpty ? 'Not specified' : value;

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neonPink),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
