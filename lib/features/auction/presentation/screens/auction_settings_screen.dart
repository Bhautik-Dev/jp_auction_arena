import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionSettingsScreen extends ConsumerStatefulWidget {
  const AuctionSettingsScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  ConsumerState<AuctionSettingsScreen> createState() =>
      _AuctionSettingsScreenState();
}

class _AuctionSettingsScreenState extends ConsumerState<AuctionSettingsScreen> {
  final List<_IncrementControllers> _tiers = [];
  String? _loadedAuctionId;
  bool _allowReentry = false;
  bool _isSaving = false;

  @override
  void didUpdateWidget(covariant AuctionSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.auctionId != oldWidget.auctionId) {
      _clearTiers();
      _loadedAuctionId = null;
    }
  }

  @override
  void dispose() {
    _clearTiers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auction = ref.watch(auctionByIdProvider(widget.auctionId));
    final rules = ref.watch(auctionRulesProvider(widget.auctionId));
    if (auction.isLoading || rules.isLoading) {
      return const AppLoadingIndicator(label: 'Loading auction settings...');
    }
    if (auction.hasError) {
      return AppErrorState(
        error: auction.error!,
        onRetry: () => ref.invalidate(auctionByIdProvider(widget.auctionId)),
      );
    }
    if (rules.hasError) {
      return AppErrorState(
        error: rules.error!,
        onRetry: () => ref.invalidate(auctionRulesProvider(widget.auctionId)),
      );
    }
    final auctionValue = auction.requireValue;
    final rulesValue = rules.requireValue;
    if (_loadedAuctionId != rulesValue.auctionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedAuctionId != rulesValue.auctionId) {
          _loadRules(rulesValue);
        }
      });
    }
    final editable =
        auctionValue.status == AuctionStatus.draft ||
        auctionValue.status == AuctionStatus.ready;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Auction Settings & Rules',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(auctionValue.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Auction configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingRow('Auction type', auctionValue.auctionType.label),
        _SettingRow(
          'Cricket format',
          auctionValue.cricketFormat == CricketFormat.custom
              ? auctionValue.customFormat ?? 'Custom'
              : auctionValue.cricketFormat.label,
        ),
        _SettingRow(
          'Purse per team',
          NumberFormat.currency(
            name: auctionValue.baseCurrency,
            symbol: '${auctionValue.baseCurrency} ',
            decimalDigits: 0,
          ).format(auctionValue.totalPursePerTeam),
        ),
        _SettingRow('Currency', auctionValue.baseCurrency),
        _SettingRow('Maximum teams', '${auctionValue.maxTeams}'),
        _SettingRow(
          'Squad size',
          '${auctionValue.minPlayersPerTeam}–${auctionValue.maxPlayersPerTeam}',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: editable
                ? () => context.go(RouteNames.auctionEditPath(auctionValue.id))
                : null,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Auction Details'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Bid increments', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'The increment for a new bid is selected by the current bid amount. '
          'Player registration price is the starting price.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < _tiers.length; index++)
          _buildTierRow(context, index, enabled: editable),
        if (editable)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addTier,
              icon: const Icon(Icons.add),
              label: const Text('Add increment tier'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow unsold players to re-enter later'),
          subtitle: const Text(
            'Stored as an auction rule; round management is added in a later point.',
          ),
          value: _allowReentry,
          onChanged: editable
              ? (value) => setState(() => _allowReentry = value)
              : null,
        ),
        if (!editable)
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Auction rules are read-only'),
              subtitle: Text(
                'Configuration cannot be changed after the auction becomes live.',
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: editable && !_isSaving ? _saveRules : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Auction Rules'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Configuration only'),
            subtitle: Text(
              'Rules are saved per auction. This phase does not run live bids, '
              'change purse balances, or process unsold rounds.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierRow(
    BuildContext context,
    int index, {
    required bool enabled,
  }) {
    final tier = _tiers[index];
    final currency = ref
        .watch(auctionByIdProvider(widget.auctionId))
        .whenOrNull(data: (auction) => auction.baseCurrency);
    final prefix = currency == null ? '' : '$currency ';
    final minimumBidField = TextFormField(
      controller: tier.minimumBid,
      enabled: enabled && index != 0,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Current bid from',
        prefixText: prefix,
        helperText: index == 0 ? 'Starting tier' : null,
      ),
    );
    final incrementField = TextFormField(
      controller: tier.increment,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Increase by', prefixText: prefix),
    );
    final removeButton = index > 0 && enabled
        ? IconButton(
            tooltip: 'Remove increment tier',
            onPressed: () => _removeTier(index),
            icon: const Icon(Icons.delete_outline),
          )
        : const SizedBox(width: 48);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                Expanded(child: minimumBidField),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: incrementField),
                removeButton,
              ],
            );
          }
          return Column(
            children: [
              minimumBidField,
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: incrementField),
                  removeButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _loadRules(AuctionRuleSet rules) {
    _clearTiers();
    _tiers.addAll(
      rules.bidIncrementTiers.map(
        (tier) => _IncrementControllers.fromTier(tier),
      ),
    );
    if (_tiers.isEmpty) _tiers.add(_IncrementControllers.defaultTier());
    _allowReentry = rules.allowUnsoldPlayerReentry;
    _loadedAuctionId = rules.auctionId;
    setState(() {});
  }

  void _addTier() {
    setState(() => _tiers.add(_IncrementControllers.empty()));
  }

  void _removeTier(int index) {
    setState(() {
      _tiers.removeAt(index).dispose();
    });
  }

  Future<void> _saveRules() async {
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) {
      _showMessage('Your session is unavailable. Sign in again to continue.');
      return;
    }
    final parsed = <BidIncrementTier>[];
    for (final tier in _tiers) {
      final minimumBid = int.tryParse(tier.minimumBid.text.trim());
      final increment = int.tryParse(tier.increment.text.trim());
      if (minimumBid == null || increment == null) {
        _showMessage('Enter valid whole-number bid thresholds and increments.');
        return;
      }
      parsed.add(
        BidIncrementTier(minimumBid: minimumBid, increment: increment),
      );
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(auctionRuleManagementServiceProvider)
          .saveRules(
            session.user,
            AuctionRuleSet(
              auctionId: widget.auctionId,
              bidIncrementTiers: parsed,
              allowUnsoldPlayerReentry: _allowReentry,
            ),
          );
      ref.invalidate(auctionRulesProvider(widget.auctionId));
      if (mounted) _showMessage('Auction rules saved.');
    } on AuctionException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearTiers() {
    for (final tier in _tiers) {
      tier.dispose();
    }
    _tiers.clear();
  }
}

class _IncrementControllers {
  _IncrementControllers(this.minimumBid, this.increment);

  factory _IncrementControllers.fromTier(BidIncrementTier tier) =>
      _IncrementControllers(
        TextEditingController(text: '${tier.minimumBid}'),
        TextEditingController(text: '${tier.increment}'),
      );

  factory _IncrementControllers.defaultTier() => _IncrementControllers.fromTier(
    const BidIncrementTier(minimumBid: 0, increment: 1000),
  );

  factory _IncrementControllers.empty() =>
      _IncrementControllers(TextEditingController(), TextEditingController());

  final TextEditingController minimumBid;
  final TextEditingController increment;

  void dispose() {
    minimumBid.dispose();
    increment.dispose();
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
