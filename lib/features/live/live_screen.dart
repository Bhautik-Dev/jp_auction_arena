import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/supabase/live_auction_client.dart';
import '../../core/providers/live_state_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/enums.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  Timer? _autoSellTimer;
  bool _autoSellScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = ref.read(activeAuctionProvider);
      if (active != null) {
        ref.read(liveAuctionNotifierProvider.notifier).start(active.id);
      }
    });
  }

  @override
  void dispose() {
    _autoSellTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveAuctionStateProvider);
    final liveError = ref.watch(liveAuctionErrorProvider);
    final activeAuction = ref.watch(activeAuctionProvider);

    if (activeAuction == null) {
      return _buildNoAuction();
    }

    if (liveState.auctionId != activeAuction.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(liveAuctionNotifierProvider.notifier).start(activeAuction.id);
      });
    }

    final stateRow = liveState.auctionState;
    final isLive = stateRow?['is_live'] == true;
    final isPaused = stateRow?['is_paused'] == true;
    final currentPlayerId = stateRow?['current_player_id'] as String?;
    final currentBid = (stateRow?['current_bid_amount'] as num?)?.toDouble();
    final currentTeamId = stateRow?['current_team_id'] as String?;
    final secondsRemaining = liveState.secondsRemaining;
    final bidCount = (stateRow?['bid_count'] as num?)?.toInt() ?? 0;

    dynamic currentPlayer;
    if (currentPlayerId != null) {
      currentPlayer = liveState.players.firstWhere(
        (p) => (p as dynamic).id == currentPlayerId,
        orElse: () => null,
      );
    }

    dynamic leadingTeam;
    if (currentTeamId != null) {
      leadingTeam = liveState.teams.firstWhere(
        (t) => (t as dynamic).id == currentTeamId,
        orElse: () => null,
      );
    }

    if (isLive && !isPaused && secondsRemaining <= 0 && currentPlayerId != null && currentTeamId != null && !_autoSellScheduled) {
      _autoSellScheduled = true;
      _startAutoSellTimer(activeAuction.id);
    } else if (!isLive || isPaused || secondsRemaining > 0 || currentPlayerId == null || currentTeamId == null) {
      _autoSellScheduled = false;
      _autoSellTimer?.cancel();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.all(14),
              color: AppColors.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeAuction.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Operator Live Desk • ${activeAuction.venue}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: liveState.isConnected
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: liveState.isConnected
                                        ? AppColors.success
                                        : AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  liveState.isConnected ? 'LIVE' : 'OFFLINE',
                                  style: TextStyle(
                                    color: liveState.isConnected
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (liveError != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.5,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      liveError,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Countdown Timer Banner
            if (isLive) ...[
              _buildCountdownBanner(secondsRemaining, isPaused),
              const SizedBox(height: 16),
            ],

            // Current Player Card
            _buildCurrentPlayerCard(currentPlayer, currentBid, leadingTeam, bidCount),
            const SizedBox(height: 20),

            // Operator Controls
            _buildOperatorControls(
              currentPlayer,
              isLive,
              isPaused,
              secondsRemaining,
              activeAuction.id,
            ),
            const SizedBox(height: 20),

            // Recent Bids
            _buildRecentBids(liveState.recentBids),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBanner(int seconds, bool paused) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final color = seconds <= 10 ? AppColors.error : AppColors.accentPink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            paused ? Icons.pause_circle_filled : Icons.timer,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 16),
          Text(
            '$minutes:$secs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            paused ? 'PAUSED' : 'LIVE HAMMER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerCard(dynamic player, double? currentBid, dynamic leadingTeam, int bidCount) {
    if (player == null) {
      return GlassCard(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.gavel_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No Player Live',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a player to begin live bidding.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]
          ),
        )); }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.accentPink,
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '#${player.playerNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            player.category,
                            style: const TextStyle(
                              color: AppColors.secondaryPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (player.isIcon == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ICON',
                              style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${player.battingStyle} • ${player.bowlingStyle}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BASE',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupee(player.basePrice),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CURRENT',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupee(currentBid ?? player.basePrice),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat('Matches', '${player.matches}'),
              _buildStat('Runs', '${player.runs}'),
              _buildStat('Wickets', '${player.wickets}'),
              _buildStat('High Score', '${player.highScore}'),
              _buildStat('Strike Rate', '${player.strikeRate}'),
            ],
          ),
          const SizedBox(height: 16),
          if (leadingTeam != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_cricket, color: AppColors.primaryBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Leading: ${leadingTeam.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatRupee(currentBid ?? 0),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Bids: $bidCount',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorControls(
    dynamic player,
    bool isLive,
    bool isPaused,
    int secondsRemaining,
    String auctionId,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operator Controls',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: isLive ? null : () => _handleStartPlayer(auctionId),
                  icon: Icons.play_arrow_rounded,
                  label: player == null ? 'Start Player' : 'Start Next',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: isLive ? null : () => _handlePickNext(auctionId),
                  icon: Icons.autorenew_rounded,
                  label: 'Pick Next',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: !isLive || player == null ? null : () => _handleUndoBid(auctionId),
                  icon: Icons.undo_rounded,
                  label: 'Undo Bid',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: !isLive ? null : () => _handlePauseResume(isPaused, auctionId),
                  icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_filled,
                  label: isPaused ? 'Resume' : 'Pause',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: isLive && player != null ? () => _handleSell(auctionId) : null,
                  icon: Icons.gavel_rounded,
                  label: 'Hammer SOLD',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: isLive && player != null ? () => _handleUnsold(auctionId) : null,
                  icon: Icons.remove_circle_rounded,
                  label: 'Mark UNSOLD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: isLive ? null : () => _handleReset(auctionId),
                  icon: Icons.refresh_rounded,
                  label: 'Reset Player',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: player != null && player.status == PlayerStatus.sold ? () => _handleRelease(player.id) : null,
                  icon: Icons.logout_rounded,
                  label: 'Release Player',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: !isLive ? null : () => _handleComplete(auctionId),
                  icon: Icons.check_circle_rounded,
                  label: 'Complete Auction',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBids(List<dynamic> bids) {
    if (bids.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Bids',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...bids.take(5).map((bid) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      (bid['team_name'] as String? ?? 'Team'),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatRupee((bid['amount'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoAuction() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_cricket, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No Active Auction',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select an auction from the dashboard to start live bidding.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () => context.go('/dashboard'),
              icon: Icons.dashboard_rounded,
              label: 'Go to Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartPlayer(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.startPlayer(
      auctionId: auctionId,
      playerId: '',
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    }
  }

  Future<void> _handlePickNext(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.pickNextPlayer(
      auctionId: auctionId,
      mode: 'auto',
    ));

    if (result.success && mounted) {
      AppToast.showSuccess(
        context,
        'Next player: ${result.data?['player_name']} (#${result.data?['player_no']}) at ${formatRupee(result.data?['base_price'])}',
      );
    } else if (mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    }
  }

  Future<void> _handleUndoBid(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.undoLastBid(
      auctionId: auctionId,
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    }
  }

  Future<void> _handlePauseResume(bool isPaused, String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = isPaused
        ? await notifier.callRpc(() => LiveAuctionClient.instance.resumeAuction(auctionId: auctionId))
        : await notifier.callRpc(() => LiveAuctionClient.instance.pauseAuction(auctionId: auctionId));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    }
  }

  Future<void> _handleSell(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.sellPlayer(
      auctionId: auctionId,
    ));

    _autoSellScheduled = false;

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    } else if (mounted) {
      AppToast.showSuccess(context, 'Player sold!');
    }
  }

  Future<void> _handleUnsold(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.markUnsold(
      auctionId: auctionId,
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    } else if (mounted) {
      AppToast.showSuccess(context, 'Player marked unsold.');
    }
  }

  Future<void> _handleReset(String auctionId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.resetPlayer(
      auctionId: auctionId,
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    } else if (mounted) {
      AppToast.showSuccess(context, 'Player reset.');
    }
  }

  Future<void> _handleRelease(String playerId) async {
    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.releasePlayer(
      playerId: playerId,
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    } else if (mounted) {
      AppToast.showSuccess(context, 'Player released.');
    }
  }

  Future<void> _handleComplete(String auctionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Complete Auction?', style: TextStyle(color: Colors.white)),
        content: const Text('Mark this auction as completed. No more bidding will be allowed.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          GradientButton(onPressed: () => Navigator.pop(ctx, true), label: 'Complete'),
        ],
      ),
    );

    if (confirm != true) return;

    final notifier = ref.read(liveAuctionNotifierProvider.notifier);
    final result = await notifier.callRpc(() => LiveAuctionClient.instance.completeAuction(
      auctionId: auctionId,
    ));

    if (!result.success && mounted) {
      AppToast.showError(
        context,
        LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage),
      );
    } else if (mounted) {
      AppToast.showSuccess(context, 'Auction completed.');
    }
  }

  void _startAutoSellTimer(String auctionId) {
    _autoSellTimer?.cancel();
    _autoSellTimer = Timer(const Duration(seconds: 2), () async {
      final state = ref.read(liveAuctionStateProvider);
      if (state.auctionState?['is_live'] == true &&
          state.auctionState?['is_paused'] != true &&
          state.secondsRemaining <= 0 &&
          state.auctionState?['current_team_id'] != null) {
        await _handleSell(auctionId);
      }
    });
  }
}
