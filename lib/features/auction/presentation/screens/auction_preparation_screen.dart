import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_preparation_snapshot.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_preparation_providers.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionPreparationScreen extends ConsumerStatefulWidget {
  const AuctionPreparationScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  ConsumerState<AuctionPreparationScreen> createState() =>
      _AuctionPreparationScreenState();
}

class _AuctionPreparationScreenState
    extends ConsumerState<AuctionPreparationScreen> {
  final _minimumPrice = TextEditingController();
  final _maximumPrice = TextEditingController();
  PlayerCategory? _category;
  PlayerStatus? _status;
  _EligibilityFilter _eligibility = _EligibilityFilter.all;
  bool _isSaving = false;

  @override
  void dispose() {
    _minimumPrice.dispose();
    _maximumPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(auctionPreparationProvider(widget.auctionId))
      .when(
        loading: () =>
            const AppLoadingIndicator(label: 'Loading auction preparation...'),
        error: (error, stackTrace) => AppErrorState(
          error: error,
          onRetry: () =>
              ref.invalidate(auctionPreparationProvider(widget.auctionId)),
        ),
        data: _content,
      );

  Widget _content(AuctionPreparationSnapshot snapshot) {
    final mode = snapshot.playerOrderMode;
    final canEdit =
        snapshot.auction.status == AuctionStatus.draft ||
        snapshot.auction.status == AuctionStatus.ready;
    final queuedIds = snapshot.queuedPlayerIds.toSet();
    final minPrice = int.tryParse(_minimumPrice.text.trim());
    final maxPrice = int.tryParse(_maximumPrice.text.trim());
    final filtered = snapshot.registeredPlayers.where((player) {
      final reason = snapshot.ineligibleReasons[player.id];
      if (_category != null && player.category != _category) return false;
      if (_status != null && player.status != _status) return false;
      if (minPrice != null && player.basePrice < minPrice) return false;
      if (maxPrice != null && player.basePrice > maxPrice) return false;
      return switch (_eligibility) {
        _EligibilityFilter.all => true,
        _EligibilityFilter.eligible => reason == null,
        _EligibilityFilter.ineligible => reason != null,
      };
    }).toList();
    final playerById = {
      for (final player in snapshot.registeredPlayers) player.id: player,
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Auction Preparation',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Chip(label: Text(snapshot.auction.status.label)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(snapshot.auction.name),
        const SizedBox(height: AppSpacing.md),
        _readinessCard(snapshot, canEdit),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Player auction queue',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (canEdit &&
                mode != PlayerOrderMode.manual &&
                snapshot.queuedPlayerIds.length > 1)
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _runAction(
                        ref
                            .read(auctionPreparationServiceProvider)
                            .applyConfiguredOrder(_actor, widget.auctionId),
                      ),
                icon: const Icon(Icons.shuffle),
                label: Text('Apply ${mode.label}'),
              ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configured order: ${mode.label}'),
                if (snapshot.queuedPlayerIds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'The auction queue is empty. Add eligible registered players below.',
                    ),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: mode == PlayerOrderMode.manual,
                    onReorder: mode == PlayerOrderMode.manual && canEdit
                        ? (oldIndex, newIndex) {
                            final ids = [...snapshot.queuedPlayerIds];
                            if (newIndex > oldIndex) newIndex--;
                            final id = ids.removeAt(oldIndex);
                            ids.insert(newIndex, id);
                            _runAction(
                              ref
                                  .read(auctionPreparationServiceProvider)
                                  .reorderQueue(
                                    _actor,
                                    auctionId: widget.auctionId,
                                    orderedPlayerIds: ids,
                                  ),
                            );
                          }
                        : (oldIndex, newIndex) {},
                    children: [
                      for (
                        var index = 0;
                        index < snapshot.queuedPlayerIds.length;
                        index++
                      )
                        _queuedPlayer(
                          index,
                          snapshot.queuedPlayerIds[index],
                          playerById[snapshot.queuedPlayerIds[index]],
                          snapshot,
                          canEdit && mode == PlayerOrderMode.manual,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Registered players',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        _filters(),
        const SizedBox(height: AppSpacing.sm),
        Text('${filtered.length} player(s) match the selected filters.'),
        if (filtered.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.person_search_outlined),
              title: Text('No registered players match these filters.'),
            ),
          )
        else
          for (final player in filtered)
            _registeredPlayer(
              player,
              snapshot,
              canEdit,
              queuedIds.contains(player.id),
            ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () =>
              context.go(RouteNames.auctionSettingsPath(widget.auctionId)),
          icon: const Icon(Icons.tune),
          label: const Text('Review Auction Rules'),
        ),
      ],
    );
  }

  Widget _readinessCard(
    AuctionPreparationSnapshot snapshot,
    bool canEdit,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _readinessHeader(snapshot, canEdit),
          const SizedBox(height: AppSpacing.sm),
          for (final item in snapshot.readinessItems)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                item.isComplete
                    ? Icons.check_circle_outline
                    : item.isBlocking
                    ? Icons.error_outline
                    : Icons.info_outline,
                color: item.isComplete
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
              ),
              title: Text(item.label),
              subtitle: Text(item.details),
            ),
          if (!snapshot.isReady)
            Text(
              'Complete all blocking checks before marking this auction Ready.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    ),
  );

  Widget _readinessHeader(AuctionPreparationSnapshot snapshot, bool canEdit) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final title = Row(
            children: [
              Icon(
                snapshot.isReady ? Icons.check_circle : Icons.fact_check,
                color: snapshot.isReady
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Auction readiness checklist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          );
          if (snapshot.auction.status != AuctionStatus.draft) return title;
          final button = FilledButton(
            onPressed: !canEdit || !snapshot.isReady || _isSaving
                ? null
                : _markReady,
            child: Text(_isSaving ? 'Saving...' : 'Mark Auction Ready'),
          );
          return constraints.maxWidth < 480
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.sm),
                    button,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.sm),
                    button,
                  ],
                );
        },
      );

  Widget _filters() => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 680
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpacing.sm * 2) / 3;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: width,
                child: DropdownButtonFormField<PlayerCategory?>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem<PlayerCategory?>(
                      child: Text('All categories'),
                    ),
                    for (final category in PlayerCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<PlayerStatus?>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Registration status',
                  ),
                  items: [
                    const DropdownMenuItem<PlayerStatus?>(
                      child: Text('All statuses'),
                    ),
                    for (final status in PlayerStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<_EligibilityFilter>(
                  initialValue: _eligibility,
                  decoration: const InputDecoration(labelText: 'Eligibility'),
                  items: [
                    for (final option in _EligibilityFilter.values)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _eligibility = value ?? _EligibilityFilter.all,
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _minimumPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum base price',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _maximumPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum base price',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _category = null;
                  _status = null;
                  _eligibility = _EligibilityFilter.all;
                  _minimumPrice.clear();
                  _maximumPrice.clear();
                }),
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _registeredPlayer(
    Player player,
    AuctionPreparationSnapshot snapshot,
    bool canEdit,
    bool queued,
  ) {
    final reason = snapshot.ineligibleReasons[player.id];
    final currency = NumberFormat.currency(
      name: snapshot.auction.baseCurrency,
      symbol: '${snapshot.auction.baseCurrency} ',
      decimalDigits: 0,
    ).format(player.basePrice);
    return Card(
      child: ListTile(
        leading: _playerAvatar(player),
        title: Text(player.name),
        subtitle: Text(
          '${player.category.label} · $currency · ${player.status.label}'
          '${player.battingStyle.trim().isEmpty ? '' : ' · ${player.battingStyle}'}'
          '${player.bowlingStyle.trim().isEmpty ? '' : ' · ${player.bowlingStyle}'}'
          '${reason == null ? '' : '\nIneligible: $reason'}',
        ),
        isThreeLine: reason != null,
        trailing: Wrap(
          spacing: AppSpacing.xs,
          children: [
            IconButton(
              tooltip: 'Review player details',
              onPressed: () => context.go(
                RouteNames.auctionPlayerDetailPath(widget.auctionId, player.id),
              ),
              icon: const Icon(Icons.open_in_new),
            ),
            if (queued)
              const Chip(label: Text('Queued'))
            else if (reason != null)
              const Chip(label: Text('Ineligible'))
            else
              FilledButton.tonal(
                onPressed: !canEdit || _isSaving
                    ? null
                    : () => _runAction(
                        ref
                            .read(auctionPreparationServiceProvider)
                            .addToQueue(
                              _actor,
                              auctionId: widget.auctionId,
                              playerId: player.id,
                            ),
                      ),
                child: const Text('Add to queue'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _queuedPlayer(
    int index,
    String playerId,
    Player? player,
    AuctionPreparationSnapshot snapshot,
    bool canReorder,
  ) {
    final label = player?.name ?? 'Missing player registration';
    final mode = snapshot.playerOrderMode;
    final currency = player == null
        ? ''
        : NumberFormat.currency(
            name: snapshot.auction.baseCurrency,
            symbol: '${snapshot.auction.baseCurrency} ',
            decimalDigits: 0,
          ).format(player.basePrice);
    return ListTile(
      key: ValueKey(playerId),
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(label),
      subtitle: Text(
        player == null
            ? 'Remove this stale queue entry before marking the auction Ready.'
            : '${player.category.label} · $currency · ${player.status.label}'
                  '${snapshot.ineligibleReasons[player.id] == null ? '' : ' · ${snapshot.ineligibleReasons[player.id]}'}',
      ),
      trailing: Wrap(
        spacing: 0,
        children: [
          IconButton(
            tooltip: 'Move $label up',
            onPressed: !canReorder || index == 0 || _isSaving
                ? null
                : () => _move(playerId, -1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Move $label down',
            onPressed:
                !canReorder ||
                    index == snapshot.queuedPlayerIds.length - 1 ||
                    _isSaving
                ? null
                : () => _move(playerId, 1),
            icon: const Icon(Icons.arrow_downward),
          ),
          if (snapshot.auction.status == AuctionStatus.draft ||
              snapshot.auction.status == AuctionStatus.ready)
            IconButton(
              tooltip: 'Remove $label from queue',
              onPressed: _isSaving
                  ? null
                  : () => _runAction(
                      ref
                          .read(auctionPreparationServiceProvider)
                          .removeFromQueue(
                            _actor,
                            auctionId: widget.auctionId,
                            playerId: playerId,
                          ),
                    ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
          if (mode == PlayerOrderMode.manual && canReorder)
            const Icon(Icons.drag_handle, semanticLabel: 'Drag to reorder'),
        ],
      ),
    );
  }

  Widget _playerAvatar(Player player) {
    final image = player.imageReference?.trim() ?? '';
    final uri = Uri.tryParse(image);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return CircleAvatar(
        child: ClipOval(
          child: Image.network(
            image,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Text(player.name.isEmpty ? '?' : player.name[0].toUpperCase()),
          ),
        ),
      );
    }
    return CircleAvatar(
      child: Text(player.name.isEmpty ? '?' : player.name[0].toUpperCase()),
    );
  }

  Future<void> _move(String playerId, int offset) => _runAction(
    ref
        .read(auctionPreparationServiceProvider)
        .movePlayer(
          _actor,
          auctionId: widget.auctionId,
          playerId: playerId,
          offset: offset,
        ),
  );

  Future<void> _markReady() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(auctionPreparationServiceProvider)
          .markReady(_actor, widget.auctionId);
      ref.invalidate(auctionByIdProvider(widget.auctionId));
      ref.invalidate(auctionsProvider);
      ref.invalidate(auctionPreparationProvider(widget.auctionId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Auction marked Ready.')));
      }
    } on AuctionException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _runAction(Future<Object?> action) async {
    setState(() => _isSaving = true);
    try {
      await action;
      ref.invalidate(auctionPreparationProvider(widget.auctionId));
    } on AuctionException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // The preparation route is restricted to signed-in auction administrators.
  // The provider surfaces a missing session before any command is available.
  AuthUser get _actor {
    final actor = ref
        .read(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    if (actor == null) {
      throw StateError('Auction preparation requires an authenticated user.');
    }
    return actor;
  }
}

enum _EligibilityFilter {
  all('All players'),
  eligible('Eligible'),
  ineligible('Ineligible');

  const _EligibilityFilter(this.label);
  final String label;
}
