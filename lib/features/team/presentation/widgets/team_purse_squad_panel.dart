import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_squad_snapshot.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_purse_squad_providers.dart';

class TeamPurseSquadPanel extends ConsumerWidget {
  const TeamPurseSquadPanel({
    required this.snapshot,
    required this.canAdjustPurse,
    this.showTeamHeader = true,
    super.key,
  });

  final TeamSquadSnapshot snapshot;
  final bool canAdjustPurse;
  final bool showTeamHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(
      name: snapshot.auction.baseCurrency,
      symbol: '${snapshot.auction.baseCurrency} ',
      decimalDigits: 0,
    );
    final remaining = snapshot.purse.remainingPurse;
    final pursePercent = snapshot.purse.adjustedInitialPurse == 0
        ? 0.0
        : (remaining / snapshot.purse.adjustedInitialPurse).clamp(0.0, 1.0);
    final params = (auctionId: snapshot.auction.id, teamId: snapshot.team.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTeamHeader) ...[
          Text(
            snapshot.team.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(snapshot.auction.name),
        ],
        Card(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Team purse',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (canAdjustPurse)
                      IconButton(
                        tooltip: 'Record purse adjustment',
                        onPressed: () => _adjustPurse(context, ref, params),
                        icon: const Icon(Icons.edit_note),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = constraints.maxWidth < 560;
                    final cards = [
                      _metric(
                        context,
                        'Initial purse',
                        formatter.format(snapshot.purse.adjustedInitialPurse),
                      ),
                      _metric(
                        context,
                        'Spent',
                        formatter.format(snapshot.purse.totalSpent),
                      ),
                      _metric(
                        context,
                        'Remaining',
                        formatter.format(remaining),
                        valueColor: remaining <= 0
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ];
                    return vertical
                        ? Column(
                            children: [
                              for (final card in cards)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: card,
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              for (final card in cards)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.sm,
                                    ),
                                    child: card,
                                  ),
                                ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: pursePercent),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${snapshot.purse.adjustments.length} audited adjustment(s) · '
                  'Updated ${DateFormat.yMMMd().add_jm().format(snapshot.lastUpdatedAt)}',
                ),
                if (snapshot.purse.adjustments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final adjustment
                      in snapshot.purse.adjustments.reversed.take(3))
                    Text(
                      '${adjustment.amount >= 0 ? '+' : ''}${formatter.format(adjustment.amount)} · '
                      '${adjustment.reason} · '
                      '${DateFormat.yMMMd().add_jm().format(adjustment.createdAt)}',
                    ),
                ],
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Squad composition',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _chip(
                      context,
                      'Squad ${snapshot.squadSize}/${snapshot.auction.maxPlayersPerTeam}',
                    ),
                    _chip(
                      context,
                      '${snapshot.remainingSquadSlots} slots remaining',
                    ),
                    for (final category in PlayerCategory.values)
                      _chip(
                        context,
                        '${category.label}: ${snapshot.categoryCounts[category] ?? 0}',
                      ),
                  ],
                ),
                if (!snapshot.meetsMinimumSquad)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Minimum squad size is ${snapshot.auction.minPlayersPerTeam}; '
                      '${snapshot.auction.minPlayersPerTeam - snapshot.squadSize} more player(s) required.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                if (snapshot.warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final warning in snapshot.warnings)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      title: Text(warning),
                    ),
                ],
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchased players',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (snapshot.purchasedPlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'No sold player assignments are recorded for this team.',
                    ),
                  )
                else
                  for (final player in snapshot.purchasedPlayers)
                    _playerRow(context, player, formatter),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _chip(BuildContext context, String label) => Chip(
    label: Text(label),
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  );

  Widget _playerRow(
    BuildContext context,
    Player player,
    NumberFormat formatter,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      child: Text(player.name.isEmpty ? '?' : player.name[0].toUpperCase()),
    ),
    title: Text(player.name),
    subtitle: Text(
      '${player.category.label}${player.isOverseas ? ' · Overseas' : ''} · '
      '${player.age == null ? 'Age not recorded' : 'Age ${player.age}'} · '
      '${player.matchesPlayed} matches · ${player.runsScored} runs · '
      '${player.wicketsTaken} wickets · '
      'Purchase price: ${player.purchasePrice == null || player.purchasePrice! <= 0 ? 'Not recorded' : formatter.format(player.purchasePrice)}',
    ),
    trailing: player.purchasePrice == null || player.purchasePrice! <= 0
        ? null
        : Text(formatter.format(player.purchasePrice)),
  );

  Future<void> _adjustPurse(
    BuildContext context,
    WidgetRef ref,
    ({String auctionId, String teamId}) params,
  ) async {
    final amount = TextEditingController();
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (context) => Form(
        key: formKey,
        child: AlertDialog(
          title: const Text('Record purse adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Adjustment amount (+ or -)',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed == 0
                      ? 'Enter a non-zero whole number'
                      : null;
                },
              ),
              TextFormField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 2,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reason for the adjustment'
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  int.parse(amount.text.trim()),
                  reason.text.trim(),
                ));
              },
              child: const Text('Record adjustment'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    reason.dispose();
    if (result == null || !context.mounted) return;
    try {
      final session = ref
          .read(authSessionProvider)
          .whenOrNull(data: (value) => value);
      if (session == null) {
        throw const TeamAccessDeniedException('Your session has expired.');
      }
      await ref
          .read(teamPurseSquadServiceProvider)
          .adjustInitialPurse(
            session.user,
            auctionId: params.auctionId,
            teamId: params.teamId,
            amount: result.$1,
            reason: result.$2,
          );
      ref.invalidate(teamPurseSquadProvider(params));
      ref.invalidate(assignedTeamPurseSquadsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purse adjustment recorded.')),
        );
      }
    } on TeamException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on AuctionException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
