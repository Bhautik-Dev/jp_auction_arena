import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/live_state_provider.dart';
import '../../../core/supabase/live_auction_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_ui_feedback.dart';

/// Provider that exposes the [LiveAuctionClient] singleton.
final liveAuctionClientProvider = Provider<LiveAuctionClient>((ref) {
  return LiveAuctionClient.instance;
});

class LiveAuctionControlScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const LiveAuctionControlScreen({super.key, required this.auctionId});

  @override
  ConsumerState<LiveAuctionControlScreen> createState() =>
      _LiveAuctionControlScreenState();
}

class _LiveAuctionControlScreenState
    extends ConsumerState<LiveAuctionControlScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _controlSub;
  bool _isClaiming = false;
  bool _hasControl = false;

  @override
  void initState() {
    super.initState();
    _claimControl();
    _watchControl();
  }

  @override
  void dispose() {
    _releaseControl();
    _controlSub?.cancel();
    super.dispose();
  }

  /// Claim control of this auction by setting controlling_operator_id.
  Future<void> _claimControl() async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isClaiming = true);

    try {
      // Claim control via RPC (validates operator permission server-side)
      final result = await client.rpc('claim_auction_control', params: {
        'auction_id': widget.auctionId,
        'operator_id': userId.toString(),
      }).single();

      final success = result['success'] as bool? ?? false;
      if (mounted) setState(() => _hasControl = success);
    } catch (_) {
      if (mounted) setState(() => _hasControl = false);
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  /// Release control when leaving this screen.
  Future<void> _releaseControl() async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Release control via RPC (validates operator permission server-side)
      await client.rpc('release_auction_control', params: {
        'auction_id': widget.auctionId,
      });
    } catch (_) {
      // Ignore release errors
    }
  }

  /// Watch control changes from other operators.
  void _watchControl() {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    _controlSub = client
        .from('auction_state')
        .stream(primaryKey: ['id'])
        .eq('auction_id', widget.auctionId)
        .listen((rows) {
      if (!mounted || rows.isEmpty) return;
      final row = rows.first;
      final controllingId = row['controlling_operator_id'] as String?;
      final currentUserId =
          client.auth.currentUser?.id.toString();

      if (mounted) {
        setState(() {
          _hasControl = controllingId == currentUserId ||
              controllingId == null ||
              controllingId.isEmpty;
        });
      }
    });
  }

  Future<void> _startPlayer(Player player) async {
    final result = await ref
        .read(liveAuctionClientProvider)
        .startPlayer(auctionId: widget.auctionId, playerId: player.id);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Start player failed');
    }
  }

  Future<void> _placeBid(Team team, double amount) async {
    final result = await ref.read(liveAuctionClientProvider).placeBid(
      auctionId: widget.auctionId,
      teamId: team.id,
      amount: amount,
    );
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Bid failed');
    }
  }

  Future<void> _sellPlayer() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Sell Player?',
      content:
          'Sell the current player to the leading bidder at the current bid amount?',
      confirmText: 'Sell',
    );
    if (confirm != true) return;

    final result = await ref
        .read(liveAuctionClientProvider)
        .sellPlayer(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Sell failed');
    }
  }

  Future<void> _markUnsold() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Mark Unsold?',
      content:
          'Mark the current player as unsold? No team will acquire this player.',
      confirmText: 'Unsold',
    );
    if (confirm != true) return;

    final result = await ref
        .read(liveAuctionClientProvider)
        .markUnsold(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Unsold failed');
    }
  }

  Future<void> _pauseAuction() async {
    final result = await ref
        .read(liveAuctionClientProvider)
        .pauseAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Pause failed');
    }
  }

  Future<void> _resumeAuction() async {
    final result = await ref
        .read(liveAuctionClientProvider)
        .resumeAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'Resume failed');
    }
  }

  Future<void> _endAuction() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'End Auction?',
      content:
          'End this auction completely. No further bidding will be possible.',
      confirmText: 'End',
      isDestructive: true,
    );
    if (confirm != true) return;

    final result = await ref
        .read(liveAuctionClientProvider)
        .completeAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      AppToast.showError(context, result.errorMessage ?? 'End auction failed');
    } else if (mounted) {
      AppToast.showSuccess(context, 'Auction completed.');
      context.go('/operator-dashboard');
    }
  }

  Future<void> _pickNextPlayer({
    String mode = 'auto',
    String? category,
  }) async {
    final result = await ref
        .read(liveAuctionClientProvider)
        .pickNextPlayer(
          auctionId: widget.auctionId,
          mode: mode,
          category: category,
        );
    if (!result.success && mounted) {
      AppToast.showError(
        context,
        result.errorMessage ?? 'Failed to pick next player',
      );
      return;
    }

    final playerId = result.data?['player_id'] as String?;
    if (playerId != null && mounted) {
      // Auto-start the picked player
      final players = ref.read(liveAuctionStateProvider).players;
      final player = players.firstWhere((p) => p.id == playerId);
      await _startPlayer(player);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveAuctionStateProvider);
    final auctionState = state.auctionState ?? {};
    final currentPlayer = state.currentPlayer;
    final leadingTeam = state.leadingTeam;
    final players = state.players;
    final teams = state.teams;
    final recentBids = state.recentBids;
    final secondsRemaining = state.secondsRemaining;
    final isLive = auctionState['is_live'] == true;
    final isPaused = auctionState['is_paused'] == true;
    final currentBid = auctionState['current_bid_amount'] as double?;
    final bidCount = auctionState['bid_count'] as int? ?? 0;

    // Increment bid by auction bid_increment (default 2000)
    final nextBidAmount = ((currentBid ?? 0) + 2000);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          state.auctionId.isNotEmpty
              ? 'Live Auction'
              : 'Loading Auction...',
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isLive ? AppColors.statusLive : AppColors.textMuted)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLive
                    ? AppColors.statusLive
                    : AppColors.textMuted,
                width: 1,
              ),
            ),
            child: Text(
              isLive ? 'LIVE' : 'NOT LIVE',
              style: TextStyle(
                color: isLive ? AppColors.statusLive : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (!_hasControl)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: const Text(
                'NO CONTROL',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(width: 10),
          GradientButton(
            onPressed: () {
              _releaseControl();
              context.go('/operator-dashboard');
            },
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            width: 90,
          ),
        ],
      ),
      body: state.auctionId.isEmpty
          ? const Center(
              child: Text(
                'No auction selected.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : _hasControl == false && !_isClaiming
              ? _buildNoControlView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timer & Status
                      _buildTimerCard(
                        secondsRemaining: secondsRemaining,
                        isLive: isLive,
                        isPaused: isPaused,
                        bidCount: bidCount,
                      ),
                      const SizedBox(height: 16),

                      // Current Player
                      _buildCurrentPlayerCard(currentPlayer),
                      const SizedBox(height: 16),

                      // Current Bid
                      _buildCurrentBidCard(
                        currentBid: currentBid,
                        leadingTeam: leadingTeam,
                        teams: teams,
                        nextBid: nextBidAmount,
                        onBid: _hasControl && !isPaused && isLive
                            ? (team) => _placeBid(team, nextBidAmount)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Main Controls
                      _buildMainControls(
                        isLive: isLive,
                        isPaused: isPaused,
                        currentPlayer: currentPlayer,
                        onStartPlayer: _hasControl && isLive
                            ? (p) => _startPlayer(p)
                            : null,
                        onSell: _hasControl && isLive ? _sellPlayer : null,
                        onUnsold: _hasControl && isLive ? _markUnsold : null,
                        onPause: _hasControl && isLive && !isPaused
                            ? _pauseAuction
                            : null,
                        onResume: _hasControl && isLive && isPaused
                            ? _resumeAuction
                            : null,
                        onEnd: _hasControl ? _endAuction : null,
                        onPickNext: _hasControl && isLive
                            ? () => _pickNextPlayer()
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Teams
                      _buildTeamsSection(teams),
                      const SizedBox(height: 20),

                      // Available Players
                      _buildPlayersSection(
                        players.where(
                          (p) => p.status == PlayerStatus.available,
                        ).toList(),
                        onSelect: _hasControl && isLive
                            ? (p) => _startPlayer(p)
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Recent Bids
                      _buildRecentBids(recentBids),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoControlView() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 20),
            const Text(
              'Auction Under Control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Another operator is currently controlling this auction. '
              'Please wait or contact them to release control.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_isClaiming)
              const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              GradientButton(
                onPressed: _claimControl,
                icon: Icons.refresh_rounded,
                label: 'Retry Control',
                width: 180,
              ),
            const SizedBox(height: 12),
            GradientButton(
              onPressed: () => context.go('/operator-dashboard'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to Dashboard',
              width: 180,
              gradient: LinearGradient(
                colors: [AppColors.textMuted, AppColors.textMuted],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard({
    required int secondsRemaining,
    required bool isLive,
    required bool isPaused,
    required int bidCount,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auction Timer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$bidCount bids',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isPaused
                          ? AppColors.warning
                          : (isLive ? AppColors.statusLive : AppColors.textMuted))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaused
                        ? AppColors.warning
                        : (isLive ? AppColors.statusLive : AppColors.textMuted),
                    width: 1,
                  ),
                ),
                child: Text(
                  isPaused
                      ? 'PAUSED'
                      : (isLive ? '${secondsRemaining}s' : '--:--'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerCard(Player? player) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Player',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (player == null)
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No player selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a player to start bidding',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          )
          else
            Row(
              children: [
                _buildPlayerPhoto(player),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${player.playerNo}  •  ${player.category}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.battingStyle}  •  ${player.bowlingStyle}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatPill('Base Price', '₹${player.basePrice.toInt()}', AppColors.gold),
                          const SizedBox(width: 8),
                          _buildStatPill('Matches', '${player.matches}', AppColors.primaryBlue),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentBidCard({
    required double? currentBid,
    required Team? leadingTeam,
    required List<Team> teams,
    required double nextBid,
    required void Function(Team)? onBid,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Bid',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bid Amount',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentBid != null
                          ? '₹${currentBid.toInt()}'
                          : '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leading Team',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leadingTeam?.name ?? '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (onBid != null)
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    height: 40,
                    onPressed: () {
                      final leading = teams.firstWhere(
                        (t) => t.id == leadingTeam?.id,
                        orElse: () => teams.first,
                      );
                      onBid(leading);
                    },
                    icon: Icons.add_circle_rounded,
                    label: 'Bid+ ₹${nextBid.toInt()}',
                    width: double.infinity,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainControls({
    required bool isLive,
    required bool isPaused,
    required Player? currentPlayer,
    required void Function(Player)? onStartPlayer,
    required VoidCallback? onSell,
    required VoidCallback? onUnsold,
    required VoidCallback? onPause,
    required VoidCallback? onResume,
    required VoidCallback? onEnd,
    required VoidCallback? onPickNext,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auction Controls',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Row 1
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onPickNext != null ? () => onPickNext() : null,
                  icon: Icons.skip_next_rounded,
                  label: 'Next Player',
                  width: double.infinity,
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onStartPlayer != null && currentPlayer != null
                      ? () => onStartPlayer(currentPlayer)
                      : null,
                  icon: Icons.play_circle_rounded,
                  label: 'Start Bidding',
                  width: double.infinity,
                  isLoading: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onSell,
                  icon: Icons.check_circle_rounded,
                  label: 'Sold',
                  width: double.infinity,
                  gradient: LinearGradient(
                    colors: [AppColors.statusSold, AppColors.statusSold],
                  ),
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onUnsold,
                  icon: Icons.cancel_rounded,
                  label: 'Unsold',
                  width: double.infinity,
                  gradient: LinearGradient(
                    colors: [AppColors.statusUnsold, AppColors.statusUnsold],
                  ),
                  isLoading: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onPause,
                  icon: Icons.pause_rounded,
                  label: isPaused ? 'Resume' : 'Pause',
                  width: double.infinity,
                  gradient: LinearGradient(
                    colors: [AppColors.warning, AppColors.warning],
                  ),
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onEnd,
                  icon: Icons.stop_rounded,
                  label: 'End Auction',
                  width: double.infinity,
                  gradient: LinearGradient(
                    colors: [AppColors.error, AppColors.error],
                  ),
                  isLoading: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPhoto(Player player) {
    if (player.photoBase64 != null && player.photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(player.photoBase64!);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.8),
            AppColors.secondaryPurple.withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsSection(List<Team> teams) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Teams',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${teams.length}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...teams.map((team) {
            final purseRemaining = team.purseRemaining;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          color: AppColors.accentPink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${purseRemaining.toInt()} remaining',
                          style: TextStyle(
                            color: purseRemaining > 0
                                ? AppColors.textSecondary
                                : AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayersSection(
    List<Player> availablePlayers, {
    required void Function(Player)? onSelect,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Players',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${availablePlayers.length}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (availablePlayers.isEmpty)
            const Center(
              child: Text(
                'No available players',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availablePlayers.map((player) {
                return GestureDetector(
                  onTap: onSelect != null ? () => onSelect(player) : null,
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlayerPhotoMini(player),
                        const SizedBox(height: 8),
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${player.basePrice.toInt()}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerPhotoMini(Player player) {
    if (player.photoBase64 != null && player.photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(player.photoBase64!);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.8),
            AppColors.secondaryPurple.withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBids(List<Map<String, dynamic>> bids) {
    if (bids.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Bids',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
                children: [
                  Text(
                    bid['team_name'] ?? 'Team',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${(bid['amount'] as num?)?.toInt() ?? 0}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
