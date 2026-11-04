import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionSettingsScreen extends ConsumerWidget {
  const AuctionSettingsScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auction = ref.watch(auctionByIdProvider(auctionId));
    return auction.when(
      loading: () => const AppLoadingIndicator(label: 'Loading settings...'),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        onRetry: () => ref.invalidate(auctionByIdProvider(auctionId)),
      ),
      data: (value) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Auction Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(value.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _SettingRow('Auction type', value.auctionType.label),
          _SettingRow(
            'Cricket format',
            value.cricketFormat == CricketFormat.custom
                ? value.customFormat ?? 'Custom'
                : value.cricketFormat.label,
          ),
          _SettingRow(
            'Purse per team',
            NumberFormat.currency(
              name: value.baseCurrency,
              symbol: '${value.baseCurrency} ',
              decimalDigits: 0,
            ).format(value.totalPursePerTeam),
          ),
          _SettingRow('Currency', value.baseCurrency),
          _SettingRow('Maximum teams', '${value.maxTeams}'),
          _SettingRow(
            'Squad size',
            '${value.minPlayersPerTeam}–${value.maxPlayersPerTeam}',
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bid increments and auction rules are not configured in this '
                'phase. Live auctions cannot be edited; archived auctions '
                'remain read-only until restored.',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed:
                  value.status == AuctionStatus.draft ||
                      value.status == AuctionStatus.ready
                  ? () => context.go(RouteNames.auctionEditPath(value.id))
                  : null,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Auction Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), trailing: Text(value));
}
