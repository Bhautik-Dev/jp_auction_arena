import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({
    required this.auctionId,
    required this.playerId,
    super.key,
  });

  final String auctionId;
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (auctionId: auctionId, playerId: playerId);
    final player = ref.watch(playerForAuctionProvider(params));
    final auction = ref.watch(auctionByIdProvider(auctionId));
    if (player.isLoading || auction.isLoading) {
      return const Scaffold(
        body: SafeArea(child: AppLoadingIndicator(label: 'Loading player...')),
      );
    }
    if (player.hasError) {
      return Scaffold(
        body: SafeArea(
          child: AppErrorState(
            error: player.error!,
            onRetry: () => ref.invalidate(playerForAuctionProvider(params)),
          ),
        ),
      );
    }
    if (auction.hasError) {
      return Scaffold(
        body: SafeArea(
          child: AppErrorState(
            error: auction.error!,
            onRetry: () => ref.invalidate(auctionByIdProvider(auctionId)),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: _PlayerDetails(
          auction: auction.requireValue,
          player: player.requireValue,
        ),
      ),
    );
  }
}

class _PlayerDetails extends ConsumerWidget {
  const _PlayerDetails({required this.auction, required this.player});

  final Auction auction;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basePrice = NumberFormat.currency(
      name: auction.baseCurrency,
      symbol: '${auction.baseCurrency} ',
      decimalDigits: 0,
    ).format(player.basePrice);
    final editable =
        auction.status == AuctionStatus.draft ||
        auction.status == AuctionStatus.ready;
    final hasResult =
        player.status == PlayerStatus.sold ||
        player.status == PlayerStatus.unsold;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(
                player.name.isEmpty ? '?' : player.name.characters.first,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                player.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Chip(label: Text(player.status.label)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Category', value: player.category.label),
              _DetailRow(label: 'Base price', value: basePrice),
              _DetailRow(
                label: 'Age',
                value: player.age?.toString() ?? 'Not provided',
              ),
              _DetailRow(
                label: 'Batting style',
                value: player.battingStyle.isEmpty
                    ? 'Not provided'
                    : player.battingStyle,
              ),
              _DetailRow(
                label: 'Bowling style',
                value: player.bowlingStyle.isEmpty
                    ? 'Not provided'
                    : player.bowlingStyle,
              ),
              _DetailRow(
                label: 'Contact number',
                value: player.contactNumber ?? 'Not provided',
              ),
              _DetailRow(
                label: 'Team assignment',
                value: player.assignedTeamId ?? 'Unassigned',
              ),
              _DetailRow(
                label: 'Image reference',
                value: player.imageReference ?? 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Player statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _Stat(label: 'Matches', value: player.matchesPlayed),
              _Stat(label: 'Runs', value: player.runsScored),
              _Stat(label: 'Wickets', value: player.wicketsTaken),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasResult)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Auction result is protected'),
              subtitle: Text(
                'Sold and unsold player records cannot be edited or deleted here.',
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (editable && !hasResult)
              OutlinedButton.icon(
                onPressed: () => context.go(
                  RouteNames.auctionPlayerEditPath(auction.id, player.id),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Player'),
              ),
            if (editable && !hasResult)
              OutlinedButton.icon(
                onPressed: () => _changeAvailability(context, ref),
                icon: Icon(
                  player.status == PlayerStatus.available
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  player.status == PlayerStatus.available
                      ? 'Mark Unavailable'
                      : 'Mark Available',
                ),
              ),
            if (editable &&
                player.status == PlayerStatus.available &&
                player.assignedTeamId == null)
              TextButton.icon(
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Player'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeAvailability(BuildContext context, WidgetRef ref) async {
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) return;
    final nextStatus = player.status == PlayerStatus.available
        ? PlayerStatus.unavailable
        : PlayerStatus.available;
    try {
      await ref
          .read(playerManagementServiceProvider)
          .updateAvailability(session.user, auction.id, player.id, nextStatus);
      ref.invalidate(
        playerForAuctionProvider((auctionId: auction.id, playerId: player.id)),
      );
      ref.invalidate(playersForAuctionProvider);
    } on PlayerException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete player?'),
        content: const Text(
          'This removes the unassigned player profile from this auction. '
          'Players with auction results cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) return;
    try {
      await ref
          .read(playerManagementServiceProvider)
          .delete(session.user, auction.id, player.id);
      ref.invalidate(playersForAuctionProvider);
      if (context.mounted) {
        context.go(RouteNames.auctionPlayersPath(auction.id));
      }
    } on PlayerException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$value', style: Theme.of(context).textTheme.headlineSmall),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}
