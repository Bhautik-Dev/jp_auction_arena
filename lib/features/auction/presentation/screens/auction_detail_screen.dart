import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionDetailScreen extends ConsumerWidget {
  const AuctionDetailScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auction = ref.watch(auctionByIdProvider(auctionId));
    return auction.when(
      loading: () => const AppLoadingIndicator(label: 'Loading auction...'),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(auctionByIdProvider(auctionId)),
      ),
      data: (value) => _AuctionDetailContent(auction: value),
    );
  }
}

class _AuctionDetailContent extends ConsumerWidget {
  const _AuctionDetailContent({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localTime = TimeOfDay(
      hour: auction.startTimeMinutes ~/ 60,
      minute: auction.startTimeMinutes % 60,
    ).format(context);
    final purse = NumberFormat.currency(
      name: auction.baseCurrency,
      symbol: '${auction.baseCurrency} ',
      decimalDigits: 0,
    ).format(auction.totalPursePerTeam);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                auction.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            AuctionStatusChip(status: auction.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(auction.description),
        const SizedBox(height: 12),
        _DetailRow(
          label: 'Auction date and time',
          value:
              '${DateFormat.yMMMd().format(auction.auctionDate)} · $localTime',
        ),
        _DetailRow(label: 'Auction type', value: auction.auctionType.label),
        _DetailRow(
          label: 'Cricket format',
          value: auction.cricketFormat == CricketFormat.custom
              ? auction.customFormat ?? 'Custom'
              : auction.cricketFormat.label,
        ),
        _DetailRow(
          label: 'Location',
          value: auction.location.isEmpty ? 'Not specified' : auction.location,
        ),
        _DetailRow(label: 'Organizer', value: auction.organizerName),
        const SizedBox(height: 16),
        Text(
          'Teams and players',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Teams: Not registered'),
            subtitle: Text(
              'Auction-specific team registration is not implemented yet.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.sports_cricket_outlined),
            title: Text('Players: Not registered'),
            subtitle: Text(
              'Auction-specific player registration is not implemented yet.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Purse and squad limits',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _DetailRow(label: 'Purse per team', value: purse),
        _DetailRow(label: 'Maximum teams', value: '${auction.maxTeams}'),
        _DetailRow(
          label: 'Players per team',
          value: '${auction.minPlayersPerTeam}–${auction.maxPlayersPerTeam}',
        ),
        const SizedBox(height: 16),
        Text('Auction progress', style: Theme.of(context).textTheme.titleLarge),
        _DetailRow(
          label: 'Progress',
          value: switch (auction.status) {
            AuctionStatus.draft => 'Configuration not ready',
            AuctionStatus.ready => 'Ready to activate',
            AuctionStatus.live =>
              'Live status set; bidding controls are not implemented',
            AuctionStatus.paused =>
              'Paused; bidding controls are not implemented',
            AuctionStatus.completed => 'Completed',
            AuctionStatus.archived => 'Archived',
          },
        ),
        const SizedBox(height: 16),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (auction.status == AuctionStatus.draft ||
                auction.status == AuctionStatus.ready)
              OutlinedButton.icon(
                onPressed: () =>
                    context.go(RouteNames.auctionEditPath(auction.id)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Auction'),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  context.go(RouteNames.auctionSettingsPath(auction.id)),
              icon: const Icon(Icons.tune),
              label: const Text('Auction Settings'),
            ),
            ..._availableStatusActions(auction.status).map(
              (action) => FilledButton.tonal(
                onPressed: () => _changeStatus(context, ref, action),
                child: Text(_actionLabel(auction.status, action)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Team Management, Player Management, auction rules, and live bidding '
          'will be connected in later phases. No unrelated screens are linked here.',
        ),
      ],
    );
  }

  List<AuctionStatus> _availableStatusActions(AuctionStatus status) =>
      switch (status) {
        AuctionStatus.draft => [AuctionStatus.ready],
        AuctionStatus.ready => [AuctionStatus.draft, AuctionStatus.live],
        AuctionStatus.live => [AuctionStatus.paused, AuctionStatus.completed],
        AuctionStatus.paused => [AuctionStatus.live, AuctionStatus.completed],
        AuctionStatus.completed => [AuctionStatus.archived],
        AuctionStatus.archived => [AuctionStatus.completed],
      };

  String _actionLabel(AuctionStatus current, AuctionStatus next) {
    if (next == AuctionStatus.ready) return 'Mark Ready';
    if (next == AuctionStatus.draft) return 'Return to Draft';
    if (next == AuctionStatus.live) {
      return current == AuctionStatus.paused
          ? 'Resume Auction'
          : 'Activate Auction';
    }
    if (next == AuctionStatus.paused) return 'Pause Auction';
    if (next == AuctionStatus.completed) return 'Complete Auction';
    return 'Archive Auction';
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    AuctionStatus nextStatus,
  ) async {
    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) return;
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${nextStatus == AuctionStatus.archived ? 'Archive' : 'Set'} auction ${nextStatus.label}?',
        ),
        content: Text(
          nextStatus == AuctionStatus.live
              ? 'Only one auction can be Live at a time. This does not start live bidding.'
              : nextStatus == AuctionStatus.archived
              ? 'The completed auction will remain in history and become read-only.'
              : 'Confirm the auction status change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (shouldProceed != true) return;
    try {
      await ref
          .read(auctionManagementServiceProvider)
          .changeStatus(actor, auction.id, nextStatus);
      ref.invalidate(auctionsProvider);
      ref.invalidate(auctionHistoryProvider);
      ref.invalidate(auctionByIdProvider(auction.id));
      ref.invalidate(dashboardSnapshotProvider);
    } on AuctionException catch (error) {
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
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
