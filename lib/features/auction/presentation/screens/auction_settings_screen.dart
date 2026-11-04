import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_rule_set.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_mode.dart';
import 'package:jp_auction_arena/features/auction/domain/models/bid_increment_tier.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/models/player_order_mode.dart';
import 'package:jp_auction_arena/features/auction/presentation/providers/auction_providers.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class AuctionSettingsScreen extends ConsumerStatefulWidget {
  const AuctionSettingsScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  ConsumerState<AuctionSettingsScreen> createState() =>
      _AuctionSettingsScreenState();
}

class _AuctionSettingsScreenState extends ConsumerState<AuctionSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_TierControllers> _tiers = [];
  final _fixedIncrement = TextEditingController();
  final _defaultBasePrice = TextEditingController();
  final _timerDuration = TextEditingController();
  final _warningThreshold = TextEditingController();
  final _extensionDuration = TextEditingController();
  final _extensionCount = TextEditingController();
  final _overseasLimit = TextEditingController();
  final _wicketkeeperLimit = TextEditingController();
  final _unsoldReentries = TextEditingController();
  final Map<PlayerCategory, TextEditingController> _categoryPrices = {
    for (final category in PlayerCategory.values)
      category: TextEditingController(),
  };
  final Map<PlayerCategory, TextEditingController> _categoryMaximums = {
    for (final category in PlayerCategory.values)
      category: TextEditingController(),
  };

  String? _loadedAuctionId;
  AuctionRuleSet? _savedRules;
  BidIncrementMode _incrementMode = BidIncrementMode.tiered;
  PlayerOrderMode _playerOrderMode = PlayerOrderMode.manual;
  bool _allowReentry = false;
  bool _timerExtensionEnabled = false;
  bool _isSaving = false;

  @override
  void didUpdateWidget(covariant AuctionSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.auctionId != oldWidget.auctionId) {
      _clearTiers();
      _loadedAuctionId = null;
      _savedRules = null;
    }
  }

  @override
  void dispose() {
    _clearTiers();
    _fixedIncrement.dispose();
    _defaultBasePrice.dispose();
    _timerDuration.dispose();
    _warningThreshold.dispose();
    _extensionDuration.dispose();
    _extensionCount.dispose();
    _overseasLimit.dispose();
    _wicketkeeperLimit.dispose();
    _unsoldReentries.dispose();
    for (final controller in [
      ..._categoryPrices.values,
      ..._categoryMaximums.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auction = ref.watch(auctionByIdProvider(widget.auctionId));
    final rules = ref.watch(auctionRulesProvider(widget.auctionId));
    if (auction.isLoading || rules.isLoading) {
      return const AppLoadingIndicator(label: 'Loading auction rules...');
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
        _loadedAuctionId == widget.auctionId &&
        (auctionValue.status == AuctionStatus.draft ||
            auctionValue.status == AuctionStatus.ready);

    return LayoutBuilder(
      builder: (context, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Auction Rules & Configuration',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  auctionValue.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!editable)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('Critical auction rules are read-only'),
                      subtitle: Text(
                        'Rules cannot be changed after this auction becomes Live.',
                      ),
                    ),
                  ),
                _section(
                  context,
                  title: 'Auction format and team configuration',
                  icon: Icons.sports_cricket_outlined,
                  children: [
                    _readOnlyRow(
                      context,
                      'Auction type',
                      auctionValue.auctionType.label,
                    ),
                    _readOnlyRow(
                      context,
                      'Cricket format',
                      auctionValue.cricketFormat == CricketFormat.custom
                          ? auctionValue.customFormat ?? 'Custom'
                          : auctionValue.cricketFormat.label,
                    ),
                    _readOnlyRow(
                      context,
                      'Currency',
                      '${auctionValue.baseCurrency} · ${NumberFormat.currency(name: auctionValue.baseCurrency, symbol: '${auctionValue.baseCurrency} ', decimalDigits: 0).format(auctionValue.totalPursePerTeam)} per team',
                    ),
                    _readOnlyRow(
                      context,
                      'Team capacity',
                      '${auctionValue.maxTeams}',
                    ),
                    _readOnlyRow(
                      context,
                      'Squad size',
                      '${auctionValue.minPlayersPerTeam}–${auctionValue.maxPlayersPerTeam}',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: editable
                            ? () => context.go(
                                RouteNames.auctionEditPath(auctionValue.id),
                              )
                            : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Auction, Purse & Squad Size'),
                      ),
                    ),
                    const Text(
                      'Purse and minimum/maximum squad size use the auction’s existing settings.',
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Player base-price defaults',
                  icon: Icons.sell_outlined,
                  children: [
                    _moneyField(
                      controller: _defaultBasePrice,
                      label: 'Default player base price (optional)',
                      currency: auctionValue.baseCurrency,
                      enabled: editable,
                    ),
                    for (final category in PlayerCategory.values)
                      _moneyField(
                        controller: _categoryPrices[category]!,
                        label:
                            '${category.label} base-price override (optional)',
                        currency: auctionValue.baseCurrency,
                        enabled: editable,
                      ),
                    const Text(
                      'Category overrides take precedence over the default. '
                      'Player registration remains auction-scoped.',
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Bid increment rules',
                  icon: Icons.trending_up,
                  children: [
                    DropdownButtonFormField<BidIncrementMode>(
                      initialValue: _incrementMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Increment mode',
                      ),
                      items: BidIncrementMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                          )
                          .toList(),
                      onChanged: editable
                          ? (value) {
                              if (value != null) {
                                setState(() => _incrementMode = value);
                              }
                            }
                          : null,
                    ),
                    if (_incrementMode == BidIncrementMode.fixed)
                      _integerField(
                        controller: _fixedIncrement,
                        label: 'Fixed bid increment',
                        enabled: editable,
                      )
                    else ...[
                      for (var index = 0; index < _tiers.length; index++)
                        _tierRow(
                          index,
                          currency: auctionValue.baseCurrency,
                          enabled: editable,
                        ),
                      if (editable)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addTier,
                            icon: const Icon(Icons.add),
                            label: const Text('Add increment tier'),
                          ),
                        ),
                    ],
                    const Text(
                      'A tier applies within its configured current-bid range. '
                      'Player base price is the initial bid amount.',
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Squad and category limits',
                  icon: Icons.groups_2_outlined,
                  children: [
                    for (final category in PlayerCategory.values)
                      _integerField(
                        controller: _categoryMaximums[category]!,
                        label: '${category.label} maximum (optional)',
                        enabled: editable,
                      ),
                    _integerField(
                      controller: _overseasLimit,
                      label: 'Maximum overseas players (optional)',
                      enabled: editable,
                    ),
                    _integerField(
                      controller: _wicketkeeperLimit,
                      label: 'Maximum wicketkeepers (optional)',
                      enabled: editable,
                    ),
                    const Text(
                      'Limits are saved as auction rules. The player model '
                      'does not currently identify overseas players, and '
                      'squad assignment enforcement is reserved for a later point.',
                    ),
                  ],
                ),
                _section(
                  context,
                  title: 'Auction timer',
                  icon: Icons.timer_outlined,
                  children: [
                    _integerField(
                      controller: _timerDuration,
                      label: 'Bid timer duration (seconds)',
                      enabled: editable,
                    ),
                    _integerField(
                      controller: _warningThreshold,
                      label: 'Warning threshold (seconds)',
                      enabled: editable,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable bid timer extension'),
                      value: _timerExtensionEnabled,
                      onChanged: editable
                          ? (value) {
                              setState(() {
                                _timerExtensionEnabled = value;
                                if (value) {
                                  if (_asPositiveInt(_extensionDuration) ==
                                      null) {
                                    _extensionDuration.text = '15';
                                  }
                                  if (_asPositiveInt(_extensionCount) == null) {
                                    _extensionCount.text = '1';
                                  }
                                }
                              });
                            }
                          : null,
                    ),
                    if (_timerExtensionEnabled) ...[
                      _integerField(
                        controller: _extensionDuration,
                        label: 'Extension duration (seconds)',
                        enabled: editable,
                      ),
                      _integerField(
                        controller: _extensionCount,
                        label: 'Maximum extension count',
                        enabled: editable,
                      ),
                    ],
                  ],
                ),
                _section(
                  context,
                  title: 'Player order and unsold players',
                  icon: Icons.format_list_numbered,
                  children: [
                    DropdownButtonFormField<PlayerOrderMode>(
                      initialValue: _playerOrderMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Player order',
                      ),
                      items: PlayerOrderMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                          )
                          .toList(),
                      onChanged: editable
                          ? (value) {
                              if (value != null) {
                                setState(() => _playerOrderMode = value);
                              }
                            }
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Allow unsold players to re-enter the auction',
                      ),
                      value: _allowReentry,
                      onChanged: editable
                          ? (value) {
                              setState(() {
                                _allowReentry = value;
                                if (value && _unsoldReentries.text.isEmpty) {
                                  _unsoldReentries.text = '1';
                                }
                              });
                            }
                          : null,
                    ),
                    if (_allowReentry)
                      _integerField(
                        controller: _unsoldReentries,
                        label: 'Maximum re-entry rounds (optional)',
                        enabled: editable,
                      ),
                    const Text(
                      'Ordering and re-entry are stored as configuration; '
                      'live sequencing and re-auction execution are not implemented.',
                    ),
                  ],
                ),
                _summaryCard(context, auctionValue, rulesValue),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: editable && !_isSaving ? _saveRules : null,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Rules'),
                    ),
                    OutlinedButton(
                      onPressed: _isSaving ? null : _cancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Configuration only: no live bidding, purse deductions, '
                  'player purchases, timer execution, or sold-player transactions '
                  'are performed in this phase.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _readOnlyRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            Text(value),
          ],
        ),
      );

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    required String currency,
    required bool enabled,
    bool allowZero = false,
    bool requiredValue = false,
    Key? key,
  }) => TextFormField(
    key: key,
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(labelText: label, prefixText: '$currency '),
    validator: (value) => _validateOptionalPositive(
      value,
      label,
      allowZero: allowZero,
      requiredValue: requiredValue,
    ),
  );

  Widget _integerField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(labelText: label),
  );

  Widget _tierRow(
    int index, {
    required String currency,
    required bool enabled,
  }) {
    final tier = _tiers[index];
    final minimum = _moneyField(
      controller: tier.minimumBid,
      label: 'Minimum current bid',
      currency: currency,
      enabled: enabled,
      allowZero: true,
      requiredValue: true,
      key: ValueKey('tier-$index-minimum'),
    );
    final maximum = _moneyField(
      controller: tier.maximumBid,
      label: 'Maximum current bid (optional)',
      currency: currency,
      enabled: enabled,
      requiredValue: false,
      key: ValueKey('tier-$index-maximum'),
    );
    final increment = _moneyField(
      controller: tier.increment,
      label: 'Increase by',
      currency: currency,
      enabled: enabled,
      requiredValue: true,
      key: ValueKey('tier-$index-increment'),
    );
    final remove = index == 0 || !enabled
        ? const SizedBox(width: 48)
        : IconButton(
            tooltip: 'Remove increment tier',
            onPressed: () => _removeTier(index),
            icon: const Icon(Icons.delete_outline),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final fields = [minimum, maximum, increment];
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (final field in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: field,
                ),
              Align(alignment: Alignment.centerRight, child: remove),
            ],
          );
        }
        return Row(
          children: [
            for (final field in fields) ...[
              Expanded(child: field),
              const SizedBox(width: AppSpacing.sm),
            ],
            remove,
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    BuildContext context,
    Auction auction,
    AuctionRuleSet loadedRules,
  ) {
    final formatter = NumberFormat.currency(
      name: auction.baseCurrency,
      symbol: '${auction.baseCurrency} ',
      decimalDigits: 0,
    );
    final categoryCaps = PlayerCategory.values
        .where(
          (category) => _categoryMaximums[category]!.text.trim().isNotEmpty,
        )
        .map(
          (category) =>
              '${category.label}: ${_categoryMaximums[category]!.text.trim()}',
        )
        .join(', ');
    final rulesReady = _loadedAuctionId == loadedRules.auctionId;
    final incrementSummary = _incrementMode == BidIncrementMode.fixed
        ? 'Fixed ${_fixedIncrement.text} per bid'
        : '${_tiers.length} tier(s)';
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rules summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Currency: ${auction.baseCurrency}'),
            Text('Team purse: ${formatter.format(auction.totalPursePerTeam)}'),
            Text(
              'Squad size: ${auction.minPlayersPerTeam}–${auction.maxPlayersPerTeam}',
            ),
            Text(
              'Bid increments: ${rulesReady ? incrementSummary : 'Loading'}',
            ),
            Text(
              'Timer: ${_timerDuration.text}s; warning at ${_warningThreshold.text}s',
            ),
            Text('Player order: ${_playerOrderMode.label}'),
            Text('Re-enter unsold players: ${_allowReentry ? 'Yes' : 'No'}'),
            if (categoryCaps.isNotEmpty)
              Text('Category maximums: $categoryCaps'),
          ],
        ),
      ),
    );
  }

  String? _validateOptionalPositive(
    String? value,
    String label, {
    bool allowZero = false,
    bool requiredValue = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return requiredValue ? '$label is required.' : null;
    }
    final number = int.tryParse(text);
    if (number == null || number < 0 || (!allowZero && number == 0)) {
      return allowZero
          ? '$label must be a non-negative whole number.'
          : '$label must be a positive whole number.';
    }
    return null;
  }

  void _loadRules(AuctionRuleSet rules) {
    _clearTiers();
    _tiers.addAll(rules.bidIncrementTiers.map(_TierControllers.fromTier));
    if (_tiers.isEmpty) _tiers.add(_TierControllers.defaultTier());
    _incrementMode = rules.bidIncrementMode;
    _fixedIncrement.text = '${rules.fixedBidIncrement}';
    _defaultBasePrice.text = rules.defaultPlayerBasePrice?.toString() ?? '';
    for (final category in PlayerCategory.values) {
      _categoryPrices[category]!.text =
          rules.categoryBasePrices[category]?.toString() ?? '';
      _categoryMaximums[category]!.text =
          rules.categoryMaximums[category]?.toString() ?? '';
    }
    _overseasLimit.text = rules.maximumOverseasPlayers?.toString() ?? '';
    _wicketkeeperLimit.text = rules.maximumWicketkeepers?.toString() ?? '';
    _timerDuration.text = '${rules.bidTimerSeconds}';
    _warningThreshold.text = '${rules.warningThresholdSeconds}';
    _timerExtensionEnabled = rules.bidTimerExtensionEnabled;
    _extensionDuration.text = '${rules.bidTimerExtensionSeconds}';
    _extensionCount.text = '${rules.maximumBidTimerExtensions}';
    _playerOrderMode = rules.playerOrderMode;
    _allowReentry = rules.allowUnsoldPlayerReentry;
    _unsoldReentries.text = rules.maximumUnsoldReentries?.toString() ?? '';
    _loadedAuctionId = rules.auctionId;
    _savedRules = rules;
    setState(() {});
  }

  void _addTier() => setState(() => _tiers.add(_TierControllers.empty()));

  void _removeTier(int index) {
    setState(() => _tiers.removeAt(index).dispose());
  }

  void _cancel() {
    final rules = _savedRules;
    if (rules == null) return;
    _loadRules(rules);
    _showMessage('Unsaved changes were discarded.');
  }

  Future<void> _saveRules() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref
        .read(authSessionProvider)
        .whenOrNull(data: (value) => value);
    if (session == null) {
      _showMessage('Your session is unavailable. Sign in again to continue.');
      return;
    }
    try {
      final parsedTiers = <BidIncrementTier>[];
      for (final tier in _tiers) {
        final minimum = int.tryParse(tier.minimumBid.text.trim());
        final maximumText = tier.maximumBid.text.trim();
        final maximum = maximumText.isEmpty ? null : int.tryParse(maximumText);
        final increment = int.tryParse(tier.increment.text.trim());
        if (minimum == null ||
            increment == null ||
            (maximumText.isNotEmpty && maximum == null)) {
          throw const AuctionValidationException(
            'Enter valid whole-number values for each bid tier.',
          );
        }
        parsedTiers.add(
          BidIncrementTier(
            minimumBid: minimum,
            maximumBid: maximum,
            increment: increment,
          ),
        );
      }

      final rules = AuctionRuleSet(
        auctionId: widget.auctionId,
        bidIncrementMode: _incrementMode,
        fixedBidIncrement: _requiredInt(_fixedIncrement, 'Fixed increment'),
        bidIncrementTiers: parsedTiers,
        defaultPlayerBasePrice: _optionalInt(_defaultBasePrice),
        categoryBasePrices: _categoryPrices.entries
            .where((entry) => entry.value.text.trim().isNotEmpty)
            .map(
              (entry) =>
                  MapEntry(entry.key, _requiredInt(entry.value, 'Base price')),
            )
            .fold<Map<PlayerCategory, int>>({}, (map, item) {
              map[item.key] = item.value;
              return map;
            }),
        categoryMaximums: _categoryMaximums.entries
            .where((entry) => entry.value.text.trim().isNotEmpty)
            .map(
              (entry) => MapEntry(
                entry.key,
                _requiredInt(entry.value, 'Category limit'),
              ),
            )
            .fold<Map<PlayerCategory, int>>({}, (map, item) {
              map[item.key] = item.value;
              return map;
            }),
        maximumOverseasPlayers: _optionalInt(_overseasLimit),
        maximumWicketkeepers: _optionalInt(_wicketkeeperLimit),
        bidTimerSeconds: _requiredInt(_timerDuration, 'Timer duration'),
        warningThresholdSeconds: _requiredInt(
          _warningThreshold,
          'Warning threshold',
        ),
        bidTimerExtensionEnabled: _timerExtensionEnabled,
        bidTimerExtensionSeconds: _timerExtensionEnabled
            ? _requiredInt(_extensionDuration, 'Extension duration')
            : 0,
        maximumBidTimerExtensions: _timerExtensionEnabled
            ? _requiredInt(_extensionCount, 'Extension count')
            : 0,
        playerOrderMode: _playerOrderMode,
        allowUnsoldPlayerReentry: _allowReentry,
        maximumUnsoldReentries: _allowReentry
            ? _optionalInt(_unsoldReentries)
            : null,
      );
      setState(() => _isSaving = true);
      await ref
          .read(auctionRuleManagementServiceProvider)
          .saveRules(session.user, rules);
      ref.invalidate(auctionRulesProvider(widget.auctionId));
      if (mounted) {
        _loadRules(rules);
        _showMessage('Auction rules saved.');
      }
    } on AuctionException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int _requiredInt(TextEditingController controller, String label) {
    final value = int.tryParse(controller.text.trim());
    if (value == null) {
      throw AuctionValidationException('$label must be a whole number.');
    }
    return value;
  }

  int? _optionalInt(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null) {
      throw const AuctionValidationException(
        'Optional numeric settings must contain a whole number.',
      );
    }
    return value;
  }

  int? _asPositiveInt(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    return value != null && value > 0 ? value : null;
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

class _TierControllers {
  _TierControllers(this.minimumBid, this.maximumBid, this.increment);

  factory _TierControllers.fromTier(BidIncrementTier tier) => _TierControllers(
    TextEditingController(text: '${tier.minimumBid}'),
    TextEditingController(text: tier.maximumBid?.toString() ?? ''),
    TextEditingController(text: '${tier.increment}'),
  );

  factory _TierControllers.defaultTier() => _TierControllers.fromTier(
    const BidIncrementTier(minimumBid: 0, increment: 1000),
  );

  factory _TierControllers.empty() => _TierControllers(
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  );

  final TextEditingController minimumBid;
  final TextEditingController maximumBid;
  final TextEditingController increment;

  void dispose() {
    minimumBid.dispose();
    maximumBid.dispose();
    increment.dispose();
  }
}
