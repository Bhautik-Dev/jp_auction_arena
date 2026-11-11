import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  String? _selectedTeamId;
  double? _customHammerPrice;

  // Track the most recent sale or unsold action for one-click Undo
  Player? _lastHammeredPlayer;
  String? _lastTeamId;
  double? _lastSoldPrice;
  PlayerStatus? _previousStatus;

  Future<void> _recordSale(Player player, Team team, double price) async {
    // Validate team purse
    if (price > team.purseRemaining) {
      AppToast.showError(
        context,
        'Cannot sell: "${team.name}" only has ${CurrencyFormatter.formatShort(team.purseRemaining)} remaining in purse.',
      );
      return;
    }

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Confirm Player Sale',
      content: 'Sell #${player.playerNo} "${player.name}" to "${team.name}" for ${CurrencyFormatter.formatInr(price)}?',
      confirmText: 'Hammer SOLD',
    );
    if (confirm != true) return;

    // Cache state for Undo
    _lastHammeredPlayer = player;
    _lastTeamId = team.id;
    _lastSoldPrice = price;
    _previousStatus = player.status;

    // Apply mutation
    player.status = PlayerStatus.sold;
    player.soldPrice = price;
    player.soldTeamId = team.id;

    team.purseSpent += price;
    if (!team.playerIds.contains(player.id)) {
      team.playerIds.add(player.id);
    }

    await ref.read(playerRepositoryProvider).save(player);
    await ref.read(teamRepositoryProvider).save(team);

    // Save bid log
    final bid = Bid(
      id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
      auctionId: player.auctionId,
      playerId: player.id,
      teamId: team.id,
      amount: price,
      timestamp: DateTime.now(),
    );
    await ref.read(bidRepositoryProvider).save(bid);

    // Trigger auto-backup if enabled in Settings
    final settings = ref.read(settingsRepositoryProvider).getSettings();
    if (settings.autoBackupAfterSale) {
      await ref.read(dataBackupServiceProvider).createBackupJson();
    }

    if (mounted) {
      AppToast.showSuccess(
        context,
        'SOLD! "${player.name}" awarded to ${team.name} for ${CurrencyFormatter.formatInr(price)}.',
      );
      setState(() {
        _customHammerPrice = null;
      });
    }
  }

  Future<void> _markUnsold(Player player) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Mark as Unsold',
      content: 'Mark #${player.playerNo} "${player.name}" as UNSOLD for this round?',
      confirmText: 'Mark Unsold',
      isDestructive: true,
    );
    if (confirm != true) return;

    _lastHammeredPlayer = player;
    _lastTeamId = null;
    _lastSoldPrice = null;
    _previousStatus = player.status;

    player.status = PlayerStatus.unsold;
    await ref.read(playerRepositoryProvider).save(player);

    if (mounted) {
      AppToast.showSuccess(context, 'Player "${player.name}" marked as UNSOLD.');
      setState(() {
        _customHammerPrice = null;
      });
    }
  }

  Future<void> _undoLastHammer() async {
    if (_lastHammeredPlayer == null) return;

    final player = _lastHammeredPlayer!;
    final teamId = _lastTeamId;
    final soldPrice = _lastSoldPrice;

    // If it was a sale, reverse team purse and squad list
    if (teamId != null && soldPrice != null) {
      final teamRepo = ref.read(teamRepositoryProvider);
      final team = teamRepo.getById(teamId);
      if (team != null) {
        team.purseSpent = (team.purseSpent - soldPrice).clamp(0.0, double.infinity);
        team.playerIds.remove(player.id);
        await teamRepo.save(team);
      }
    }

    // Reset player state to available
    player.status = _previousStatus ?? PlayerStatus.available;
    player.soldPrice = null;
    player.soldTeamId = null;
    await ref.read(playerRepositoryProvider).save(player);

    if (mounted) {
      AppToast.showSuccess(context, 'Undone: "${player.name}" returned to available pool.');
      setState(() {
        _lastHammeredPlayer = null;
        _lastTeamId = null;
        _lastSoldPrice = null;
        _previousStatus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];

    final availablePlayers = players.where((p) => p.status == PlayerStatus.available).toList();
    final currentPlayer = availablePlayers.isNotEmpty ? availablePlayers.first : null;

    final effectiveHammerPrice = _customHammerPrice ?? (currentPlayer?.basePrice ?? 10000.0);
    final activeTeam = teams.firstWhere(
      (t) => t.id == _selectedTeamId,
      orElse: () => teams.isNotEmpty ? teams.first : Team(id: '', auctionId: '', name: 'No Team', purseTotal: 0),
    );

    return FeaturePlaceholderScreen(
      title: 'Live Auction Hammer Arena',
      description: activeAuction != null
          ? 'Live bidding desk for "${activeAuction.name}"'
          : 'Please select an auction to start live hammer bidding',
      icon: Icons.gavel_rounded,
      actionButton: Wrap(
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_lastHammeredPlayer != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.undo_rounded, size: 16),
              label: Text('Undo (${_lastHammeredPlayer!.name})'),
              onPressed: _undoLastHammer,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statusLive.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.statusLive),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.statusLive),
                SizedBox(width: 6),
                Text(
                  'HAMMER READY',
                  style: TextStyle(color: AppColors.statusLive, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        if (currentPlayer == null) ...[
          GlassCard(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 54, color: AppColors.success),
                  const SizedBox(height: 16),
                  const Text(
                    'No Available Players in Pool',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All registered players have been hammered or no players are registered yet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Live Player on Hammer Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.accentPink,
            hasGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 620;

                    final playerBio = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                          child: Text(
                            '#${currentPlayer.playerNo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    currentPlayer.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryPurple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      currentPlayer.category,
                                      style: const TextStyle(color: AppColors.secondaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (currentPlayer.isIcon)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('ICON', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${currentPlayer.battingStyle} • ${currentPlayer.bowlingStyle} • Village: ${currentPlayer.village.isNotEmpty ? currentPlayer.village : "Local"}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildMiniStat('Runs', '${currentPlayer.runs}'),
                                  _buildMiniStat('Wickets', '${currentPlayer.wickets}'),
                                  _buildMiniStat('Matches', '${currentPlayer.matches}'),
                                  _buildMiniStat('Strike Rate', '${currentPlayer.strikeRate}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final priceTimerBlock = Column(
                      crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        const Text('Base Price', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text(
                          CurrencyFormatter.formatInr(currentPlayer.basePrice),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Text(
                            '${activeAuction?.countdownSeconds ?? 30}s',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );

                    return isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              playerBio,
                              const SizedBox(height: 14),
                              priceTimerBlock,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: playerBio),
                              const SizedBox(width: 16),
                              priceTimerBlock,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                // Bidding pad
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Live Bidding Pad & Quick Teams',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Active Bid Step: +${CurrencyFormatter.formatShort(activeAuction?.bidIncrement ?? 2000)}',
                      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Quick team select buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: teams.map((team) {
                    final isSelected = team.id == activeTeam.id;
                    return ChoiceChip(
                      selected: isSelected,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.surfaceLight,
                      label: Text(
                        '${team.name} (${CurrencyFormatter.formatShort(team.purseRemaining)})',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      avatar: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.shield_outlined,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.secondaryPurple,
                      ),
                      onSelected: (_) => setState(() => _selectedTeamId = team.id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                // Price step modifier bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Hammer Price: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        CurrencyFormatter.formatInr(effectiveHammerPrice),
                        style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: effectiveHammerPrice > currentPlayer.basePrice
                            ? () {
                                final step = activeAuction?.bidIncrement ?? 2000.0;
                                setState(() {
                                  _customHammerPrice = (effectiveHammerPrice - step).clamp(currentPlayer.basePrice, double.infinity);
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          final step = activeAuction?.bidIncrement ?? 2000.0;
                          setState(() {
                            _customHammerPrice = effectiveHammerPrice + step;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => setState(() => _customHammerPrice = currentPlayer.basePrice),
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons: Unsold / Sold
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => _markUnsold(currentPlayer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Mark UNSOLD'),
                    ),
                    GradientButton(
                      width: 240,
                      onPressed: teams.isEmpty || activeTeam.id.isEmpty
                          ? null
                          : () => _recordSale(currentPlayer, activeTeam, effectiveHammerPrice),
                      icon: Icons.gavel_rounded,
                      label: 'Sold to ${activeTeam.name}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}
