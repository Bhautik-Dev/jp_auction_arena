import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_management_service.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/widgets/auction_widgets.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/dashboard/application/dashboard_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionListScreen extends ConsumerStatefulWidget {
  const AuctionListScreen({this.historyOnly = false, super.key});

  final bool historyOnly;

  @override
  ConsumerState<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends ConsumerState<AuctionListScreen> {
  final _searchController = TextEditingController();
  AuctionStatus? _status;
  bool _ascending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctions = ref.watch(
      widget.historyOnly ? auctionHistoryProvider : auctionsProvider,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              widget.historyOnly ? 'Auction History / Archives' : 'Auctions',
              style: Theme.of(context).textTheme.headlineMedium,
            );
            final createButton = FilledButton.icon(
              onPressed: () => context.go(RouteNames.auctionCreate),
              icon: const Icon(Icons.add),
              label: const Text('Create New Auction'),
            );
            if (widget.historyOnly) return title;
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 8), createButton],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                createButton,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search auctions',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            for (final status in AuctionStatus.values)
              FilterChip(
                label: Text(status.label),
                selected: _status == status,
                onSelected: (_) =>
                    setState(() => _status = _status == status ? null : status),
              ),
            IconButton(
              tooltip: _ascending ? 'Sort oldest first' : 'Sort newest first',
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        auctions.when(
          loading: () =>
              const AppLoadingIndicator(label: 'Loading auctions...'),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(
              widget.historyOnly ? auctionHistoryProvider : auctionsProvider,
            ),
          ),
          data: (items) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered =
                items.where((auction) {
                  return (_status == null || auction.status == _status) &&
                      (query.isEmpty ||
                          '${auction.name} ${auction.location} ${auction.organizerName}'
                              .toLowerCase()
                              .contains(query));
                }).toList()..sort(
                  (first, second) => _ascending
                      ? first.auctionDate.compareTo(second.auctionDate)
                      : second.auctionDate.compareTo(first.auctionDate),
                );
            if (filtered.isEmpty) {
              return AppEmptyState(
                title: widget.historyOnly
                    ? 'No completed or archived auctions'
                    : 'No auctions found',
                message: 'Create an auction or adjust your search and filters.',
              );
            }
            return Column(
              children: [
                for (final auction in filtered)
                  _AuctionListTile(
                    auction: auction,
                    historyOnly: widget.historyOnly,
                    onChanged: _refresh,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh(String id) {
    ref.invalidate(auctionsProvider);
    ref.invalidate(auctionHistoryProvider);
    ref.invalidate(auctionByIdProvider(id));
    ref.invalidate(dashboardSnapshotProvider);
  }
}

class _AuctionListTile extends ConsumerWidget {
  const _AuctionListTile({
    required this.auction,
    required this.historyOnly,
    required this.onChanged,
  });

  final Auction auction;
  final bool historyOnly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(auctionManagementServiceProvider);
    final actor = ref.watch(
      authSessionProvider.select(
        (state) => state.whenOrNull(data: (session) => session?.user),
      ),
    );
    final canEdit =
        !historyOnly &&
        (auction.status == AuctionStatus.draft ||
            auction.status == AuctionStatus.ready);
    final actions = <PopupMenuEntry<_AuctionAction>>[
      if (canEdit)
        const PopupMenuItem(
          value: _AuctionAction.edit,
          child: Text('Edit auction'),
        ),
      if (auction.status == AuctionStatus.ready && !historyOnly)
        const PopupMenuItem(
          value: _AuctionAction.activate,
          child: Text('Activate auction'),
        ),
      if (auction.status == AuctionStatus.completed)
        const PopupMenuItem(
          value: _AuctionAction.archive,
          child: Text('Archive completed auction'),
        ),
      if (auction.status == AuctionStatus.archived)
        const PopupMenuItem(
          value: _AuctionAction.restore,
          child: Text('Restore archived auction'),
        ),
    ];
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.gavel_rounded)),
            title: Text(auction.name),
            subtitle: Text(
              '${DateFormat.yMMMd().format(auction.auctionDate)} · '
              '${auction.cricketFormat.label}',
            ),
            trailing: actions.isEmpty
                ? const Icon(Icons.arrow_forward)
                : PopupMenuButton<_AuctionAction>(
                    tooltip: 'Auction actions',
                    onSelected: (action) {
                      switch (action) {
                        case _AuctionAction.edit:
                          context.go(RouteNames.auctionEditPath(auction.id));
                        case _AuctionAction.activate:
                          if (actor != null) {
                            _changeStatus(
                              context,
                              ref,
                              service,
                              actor,
                              AuctionStatus.live,
                            );
                          }
                        case _AuctionAction.archive:
                          if (actor != null) {
                            _changeStatus(
                              context,
                              ref,
                              service,
                              actor,
                              AuctionStatus.archived,
                            );
                          }
                        case _AuctionAction.restore:
                          if (actor != null) {
                            _changeStatus(
                              context,
                              ref,
                              service,
                              actor,
                              AuctionStatus.completed,
                            );
                          }
                      }
                    },
                    itemBuilder: (context) => actions,
                  ),
            onTap: () => context.go(RouteNames.auctionDetailPath(auction.id)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AuctionStatusChip(status: auction.status),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    AuctionManagementService service,
    AuthUser actor,
    AuctionStatus nextStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          nextStatus == AuctionStatus.live
              ? 'Activate this auction?'
              : '${nextStatus == AuctionStatus.archived ? 'Archive' : 'Set'} auction ${nextStatus.label}?',
        ),
        content: Text(
          nextStatus == AuctionStatus.live
              ? 'Only one auction can be Live at a time. Live bidding controls are not part of this phase.'
              : nextStatus == AuctionStatus.archived
              ? 'This completed auction will remain in history and become read-only.'
              : 'Confirm the status change to ${nextStatus.label}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              nextStatus == AuctionStatus.live ? 'Activate' : 'Confirm',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await service.changeStatus(actor, auction.id, nextStatus);
      onChanged(auction.id);
    } on AuctionException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

enum _AuctionAction { edit, activate, archive, restore }
