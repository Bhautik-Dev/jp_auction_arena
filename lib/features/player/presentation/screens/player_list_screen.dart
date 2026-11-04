import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({this.auctionId, super.key});

  final String? auctionId;

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  String? _selectedAuctionId;
  String _query = '';
  PlayerCategory? _category;
  PlayerStatus? _status;

  @override
  void initState() {
    super.initState();
    _selectedAuctionId = widget.auctionId;
  }

  @override
  void didUpdateWidget(covariant PlayerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.auctionId != oldWidget.auctionId) {
      _selectedAuctionId = widget.auctionId;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ref
          .watch(auctionsProvider)
          .when(
            loading: () =>
                const AppLoadingIndicator(label: 'Loading auctions...'),
            error: (error, stackTrace) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(auctionsProvider),
            ),
            data: _buildForAuctions,
          ),
    ),
  );

  Widget _buildForAuctions(List<Auction> auctions) {
    if (auctions.isEmpty) {
      return const AppEmptyState(
        title: 'No auctions available',
        message: 'Create or get assigned to an auction to register players.',
      );
    }
    final defaultAuction = auctions.firstWhere(
      (auction) =>
          auction.status == AuctionStatus.draft ||
          auction.status == AuctionStatus.ready,
      orElse: () => auctions.first,
    );
    final selectedId =
        auctions.any((auction) => auction.id == _selectedAuctionId)
        ? _selectedAuctionId!
        : defaultAuction.id;
    final auction = auctions.firstWhere((item) => item.id == selectedId);
    if (_selectedAuctionId != selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedAuctionId = selectedId);
      });
    }
    final canModify =
        auction.status == AuctionStatus.draft ||
        auction.status == AuctionStatus.ready;
    final currency = NumberFormat.currency(
      name: auction.baseCurrency,
      symbol: '${auction.baseCurrency} ',
      decimalDigits: 0,
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Players', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(auction.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        if (widget.auctionId == null) ...[
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Auction'),
            items: [
              for (final item in auctions)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() {
              _selectedAuctionId = value;
              _query = '';
              _category = null;
              _status = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!canModify)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Player registration is read-only'),
              subtitle: Text(
                'Player profiles cannot be changed after the auction becomes live.',
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (canModify)
              FilledButton.icon(
                onPressed: () =>
                    context.go(RouteNames.auctionPlayerCreatePath(selectedId)),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Player'),
              ),
            if (canModify)
              OutlinedButton.icon(
                onPressed: () => _importCsv(selectedId),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import CSV'),
              ),
            OutlinedButton.icon(
              onPressed: () => _exportCsv(selectedId),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy CSV export'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              decoration: const InputDecoration(
                labelText: 'Search players',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            );
            final category = DropdownButtonFormField<PlayerCategory?>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<PlayerCategory?>(
                  value: null,
                  child: Text(
                    'All categories',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final item in PlayerCategory.values)
                  DropdownMenuItem(
                    value: item,
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value),
            );
            final status = DropdownButtonFormField<PlayerStatus?>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<PlayerStatus?>(
                  value: null,
                  child: Text('All statuses', overflow: TextOverflow.ellipsis),
                ),
                for (final item in PlayerStatus.values)
                  DropdownMenuItem(
                    value: item,
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _status = value),
            );
            if (constraints.maxWidth < 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.sm),
                  category,
                  const SizedBox(height: AppSpacing.sm),
                  status,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: category),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: status),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ref
            .watch(
              playersForAuctionProvider((
                auctionId: selectedId,
                query: _query,
                category: _category,
                status: _status,
              )),
            )
            .when(
              loading: () => const SizedBox(
                height: 240,
                child: AppLoadingIndicator(label: 'Loading players...'),
              ),
              error: (error, stackTrace) => AppErrorState(
                error: error,
                onRetry: () => ref.invalidate(
                  playersForAuctionProvider((
                    auctionId: selectedId,
                    query: _query,
                    category: _category,
                    status: _status,
                  )),
                ),
              ),
              data: (players) {
                if (players.isEmpty) {
                  return const SizedBox(
                    height: 300,
                    child: AppEmptyState(
                      title: 'No players registered',
                      message:
                          'Add players to this auction or adjust your filters.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final player in players) ...[
                      AppCard(
                        onTap: () => context.push(
                          RouteNames.auctionPlayerDetailPath(
                            selectedId,
                            player.id,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                player.name.isEmpty
                                    ? '?'
                                    : player.name.characters.first,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${player.category.label} · Base ${currency.format(player.basePrice)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Chip(label: Text(player.status.label)),
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

  Future<void> _importCsv(String auctionId) async {
    final controller = TextEditingController();
    final csv = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import players from CSV'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Paste CSV',
              helperText: 'Required columns: player_name, category, base_price',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (csv == null || !mounted) return;
    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) return;
    try {
      await ref
          .read(playerManagementServiceProvider)
          .importCsv(actor, auctionId, csv);
      ref.invalidate(playersForAuctionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Players imported successfully.')),
        );
      }
    } on PlayerException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _exportCsv(String auctionId) async {
    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) return;
    try {
      final csv = await ref
          .read(playerManagementServiceProvider)
          .exportCsv(actor, auctionId);
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV copied to clipboard.')),
        );
      }
    } on PlayerException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
