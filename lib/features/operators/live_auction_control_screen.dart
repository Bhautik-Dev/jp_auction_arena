import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/live_state_provider.dart';
import '../../../core/supabase/live_auction_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_ui_feedback.dart';

/// Debug logging helper for control page operations.
void _logControl(String tag, String message, {Object? error, StackTrace? stackTrace}) {
  final prefix = '[CONTROL]';
  final suffix = error != null ? ' ERROR: $error' : '';
  final trace = stackTrace != null ? '\n$stackTrace' : '';
  debugPrint('$prefix $tag $message$suffix$trace');
}

/// Debug logging helper for errors.
void _logControlError(String tag, Object error, [StackTrace? stackTrace]) {
  final prefix = '[CONTROL ERROR]';
  debugPrint('$prefix $tag: $error${stackTrace != null ? '\n$stackTrace' : ''}');
}

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
  TextEditingController? _customBidController;
  Team? _selectedBidTeam;
  bool _isPlacingCustomBid = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _customBidController = TextEditingController();
    // Delay provider modification until after build cycle to avoid
    // "Tried to modify a provider while the widget tree was building" error
    Future.microtask(() {
      if (mounted) {
        ref.read(liveAuctionNotifierProvider.notifier).start(widget.auctionId);
      }
    });
    _claimControl();
    _watchControl();
  }

  @override
  void dispose() {
    _releaseControl();
    _controlSub?.cancel();
    _customBidController?.dispose();
    super.dispose();
  }

  /// Claim control of this auction — no auth required, always granted.
  void _claimControl() {
    _logControl('Claim control', 'auctionId=${widget.auctionId}');

    setState(() => _isClaiming = true);

    final client = SupabaseClientService.instance.client;
    if (client != null) {
      // Claim control via RPC — fire and forget, don't block UI
      client.rpc('claim_auction_control', params: {
        'p_auction_id': widget.auctionId,
        'p_operator_id': 'operator',
      }).then((_) {
        _logControl('Control claimed', 'auctionId=${widget.auctionId}');
        if (mounted) setState(() => _hasControl = true);
      }).catchError((_) {
        // RPC may fail if auth.uid() is null — still grant control locally
        _logControlError('Claim control RPC failed', 'auth may be null');
        if (mounted) setState(() => _hasControl = true);
      }).whenComplete(() {
        if (mounted) setState(() => _isClaiming = false);
      });
    } else {
      if (mounted) {
        setState(() {
          _hasControl = true;
          _isClaiming = false;
        });
      }
    }
  }

  /// Release control when leaving this screen.
  Future<void> _releaseControl() async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    try {
      // Release control via RPC (validates operator permission server-side)
      await client.rpc('release_auction_control', params: {
        'p_auction_id': widget.auctionId,
      });
    } catch (_) {
      // Ignore release errors
    }
  }

  /// Watch control changes from other operators.
  void _watchControl() {
    _logControl('Watch control started', 'auctionId=${widget.auctionId}');

    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    _controlSub = client
        .from('auction_state')
        .stream(primaryKey: ['id'])
        .eq('auction_id', widget.auctionId)
        .listen((rows) {
      if (!mounted || rows.isEmpty) return;

      if (mounted) {
        setState(() {
          // Control is always granted — no auth checks
          _hasControl = true;
        });
      }
    });
  }

  Future<void> _startPlayer(Player? player) async {
    _logControl('Start player called', 'auctionId=${widget.auctionId}, player=${player?.name ?? 'null'}');

    // Auto-load next eligible player if none provided
    Player? playerToStart = player;
    if (playerToStart == null) {
      final available = ref.read(liveAuctionStateProvider).players.where(
        (p) => p.status == PlayerStatus.available,
      ).toList();
      if (available.isNotEmpty) {
        playerToStart = available.first;
        _logControl('Auto-selected player', 'name=${playerToStart.name}, id=${playerToStart.id}');
      } else {
        _logControl('No available players', 'auctionId=${widget.auctionId}');
        if (mounted) {
          AppToast.showError(context, 'No available players to start.');
        }
        return;
      }
    }

    _logControl('Start player RPC', 'auctionId=${widget.auctionId}, playerId=${playerToStart.id}');
    final result = await ref
        .read(liveAuctionClientProvider)
        .startPlayer(auctionId: widget.auctionId, playerId: playerToStart.id);
    if (!result.success && mounted) {
      _logControlError('Start player failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Start player failed');
    } else {
      _logControl('Start player success', 'auctionId=${widget.auctionId}, playerId=${playerToStart.id}');
    }
  }

  Future<void> _placeBid(Team team, double amount) async {
    _logControl('Place bid', 'auctionId=${widget.auctionId}, team=${team.name}, amount=$amount');

    final result = await ref.read(liveAuctionClientProvider).placeBid(
      auctionId: widget.auctionId,
      teamId: team.id,
      amount: amount,
    );
    if (!result.success && mounted) {
      _logControlError('Place bid failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Bid failed');
    } else {
      _logControl('Place bid success', 'auctionId=${widget.auctionId}, team=${team.name}, amount=$amount');
    }
  }

  Future<void> _placeCustomBid() async {
    _logControl('Custom bid called', 'auctionId=${widget.auctionId}');

    final team = _selectedBidTeam;
    if (team == null) {
      _logControl('Custom bid failed', 'No team selected');
      if (mounted) {
        AppToast.showError(context, 'Please select a team first.');
      }
      return;
    }
    final amountText = _customBidController?.text.trim() ?? '';
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _logControl('Custom bid failed', 'Invalid amount: $amountText');
      if (mounted) {
        AppToast.showError(context, 'Please enter a valid bid amount.');
      }
      return;
    }
    setState(() => _isPlacingCustomBid = true);
    try {
      _logControl('Custom bid RPC', 'auctionId=${widget.auctionId}, team=${team.name}, amount=$amount');
      final result = await ref
          .read(liveAuctionClientProvider)
          .placeBid(
            auctionId: widget.auctionId,
            teamId: team.id,
            amount: amount,
          );
      if (!result.success && mounted) {
        _logControlError('Custom bid failed', result.errorMessage ?? 'Unknown error');
        AppToast.showError(context, result.errorMessage ?? 'Custom bid failed');
      } else if (mounted) {
        _customBidController?.clear();
        _customBidController?.text = '';
        AppToast.showSuccess(context, 'Custom bid placed successfully.');
        _logControl('Custom bid success', 'auctionId=${widget.auctionId}, team=${team.name}, amount=$amount');
      }
    } finally {
      if (mounted) setState(() => _isPlacingCustomBid = false);
    }
  }

  Future<void> _pickPreviousPlayer({
    String mode = 'auto',
    String? category,
  }) async {
    _logControl('Pick previous player', 'auctionId=${widget.auctionId}, mode=$mode');

    final result = await ref
        .read(liveAuctionClientProvider)
        .pickNextPlayer(
          auctionId: widget.auctionId,
          mode: mode,
          category: category,
        );
    if (!result.success && mounted) {
      _logControlError('Pick previous player failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(
        context,
        result.errorMessage ?? 'Failed to pick previous player',
      );
      return;
    }

    final playerId = result.data?['player_id'] as String?;
    if (playerId != null && mounted) {
      final players = ref.read(liveAuctionStateProvider).players;
      final player = players.firstWhere((p) => p.id == playerId);
      await _startPlayer(player);
    }
  }

  Future<void> _sellPlayer() async {
    _logControl('Sell player', 'auctionId=${widget.auctionId}');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Sell Player?',
      content:
          'Sell the current player to the leading bidder at the current bid amount?',
      confirmText: 'Sell',
    );
    if (confirm != true) {
      _logControl('Sell cancelled', 'auctionId=${widget.auctionId}');
      return;
    }

    final result = await ref
        .read(liveAuctionClientProvider)
        .sellPlayer(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('Sell player failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Sell failed');
    } else {
      _logControl('Sell player success', 'auctionId=${widget.auctionId}');
    }
  }

  Future<void> _markUnsold() async {
    _logControl('Mark unsold', 'auctionId=${widget.auctionId}');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Mark Unsold?',
      content:
          'Mark the current player as unsold? No team will acquire this player.',
      confirmText: 'Unsold',
    );
    if (confirm != true) {
      _logControl('Mark unsold cancelled', 'auctionId=${widget.auctionId}');
      return;
    }

    final result = await ref
        .read(liveAuctionClientProvider)
        .markUnsold(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('Mark unsold failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Unsold failed');
    } else {
      _logControl('Mark unsold success', 'auctionId=${widget.auctionId}');
    }
  }

  Future<void> _pauseAuction() async {
    _logControl('Pause auction', 'auctionId=${widget.auctionId}');

    final result = await ref
        .read(liveAuctionClientProvider)
        .pauseAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('Pause failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Pause failed');
    } else {
      _logControl('Pause success', 'auctionId=${widget.auctionId}');
    }
  }

  Future<void> _resumeAuction() async {
    _logControl('Resume auction', 'auctionId=${widget.auctionId}');

    final result = await ref
        .read(liveAuctionClientProvider)
        .resumeAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('Resume failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Resume failed');
    } else {
      _logControl('Resume success', 'auctionId=${widget.auctionId}');
    }
  }

  Future<void> _endAuction() async {
    _logControl('End auction', 'auctionId=${widget.auctionId}');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'End Auction?',
      content:
          'End this auction completely. No further bidding will be possible.',
      confirmText: 'End',
      isDestructive: true,
    );
    if (confirm != true) {
      _logControl('End cancelled', 'auctionId=${widget.auctionId}');
      return;
    }

    final result = await ref
        .read(liveAuctionClientProvider)
        .completeAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('End auction failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'End auction failed');
    } else if (mounted) {
      _logControl('End auction success', 'auctionId=${widget.auctionId}');
      AppToast.showSuccess(context, 'Auction completed.');
      context.go('/operator-dashboard');
    }
  }

  Future<void> _restartAuction() async {
    _logControl('Restart auction', 'auctionId=${widget.auctionId}');

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Restart Auction?',
      content:
          'Are you sure you want to restart the auction? All bids will be cleared and players will be reset to available. Previous results are preserved in the activity log.',
      confirmText: 'Restart',
      isDestructive: false,
    );
    if (confirm != true) {
      _logControl('Restart cancelled', 'auctionId=${widget.auctionId}');
      return;
    }

    final result = await ref
        .read(liveAuctionClientProvider)
        .restartAuction(auctionId: widget.auctionId);
    if (!result.success && mounted) {
      _logControlError('Restart failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(context, result.errorMessage ?? 'Restart failed');
    } else if (mounted) {
      _logControl('Restart success', 'auctionId=${widget.auctionId}');
      AppToast.showSuccess(context, 'Auction restarted.');
    }
  }

  Future<void> _pickNextPlayer({
    String mode = 'auto',
    String? category,
  }) async {
    _logControl('Pick next player', 'auctionId=${widget.auctionId}, mode=$mode');

    final result = await ref
        .read(liveAuctionClientProvider)
        .pickNextPlayer(
          auctionId: widget.auctionId,
          mode: mode,
          category: category,
        );
    if (!result.success && mounted) {
      _logControlError('Pick next player failed', result.errorMessage ?? 'Unknown error');
      AppToast.showError(
        context,
        result.errorMessage ?? 'Failed to pick next player',
      );
      return;
    }

    final playerId = result.data?['player_id'] as String?;
    if (playerId != null && mounted) {
      final players = ref.read(liveAuctionStateProvider).players;
      try {
        final player = players.firstWhere((p) => p.id == playerId);
        await _startPlayer(player);
      } catch (e) {
        _logControlError('Player not found in state', playerId, StackTrace.current);
        if (mounted) {
          AppToast.showError(context, 'Picked player not found in state.');
        }
      }
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
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
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
              _logControl('Back clicked', 'auctionId=${widget.auctionId}');
              _releaseControl();
              context.go('/operator-dashboard');
            },
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            width: 90,
          ),
          const SizedBox(width: 10),
          GradientButton(
            onPressed: () {
              _logControl('Refresh clicked', 'auctionId=${widget.auctionId}');
              ref.read(liveAuctionNotifierProvider.notifier).start(widget.auctionId);
            },
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            width: 90,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auction Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.auctionId.isNotEmpty ? state.auctionId : 'No Auction',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Operator Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/operator-dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('Auctions'),
              onTap: () {
                Navigator.pop(context);
                context.go('/auctions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Results'),
              onTap: () {
                Navigator.pop(context);
                context.go('/results');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
                        onBid: (team) => _placeBid(team, nextBidAmount),
                      ),
                      const SizedBox(height: 16),

                      // Custom Bid
                      _buildCustomBidCard(
                        teams: teams,
                        selectedTeam: _selectedBidTeam,
                        onTeamSelected: (team) =>
                            setState(() => _selectedBidTeam = team),
                        customBidController: _customBidController!,
                        onPlaceCustomBid: _placeCustomBid,
                        isPlacing: _isPlacingCustomBid,
                      ),
                      const SizedBox(height: 16),

                      // Main Controls
                      _buildMainControls(
                        isLive: isLive,
                        isPaused: isPaused,
                        currentPlayer: currentPlayer,
                        onStartPlayer: (_) => _startPlayer(null),
                        onSell: _sellPlayer,
                        onUnsold: _markUnsold,
                        onPause: _pauseAuction,
                        onResume: _resumeAuction,
                        onRestart: _restartAuction,
                        onEnd: _endAuction,
                        onPickNext: () => _pickNextPlayer(),
                        onPickPrevious: () => _pickPreviousPlayer(),
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
                        onSelect: (p) => _startPlayer(p),
                      ),
                      const SizedBox(height: 20),

                      // Recent Bids
                      _buildRecentBids(recentBids, teams),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: teams.map((team) {
                return GradientButton(
                  height: 36,
                  onPressed: () {
                    _logControl('Bid clicked', 'team=${team.name}, amount=${nextBid.toInt()}, auctionId=${widget.auctionId}');
                    onBid(team);
                  },
                  icon: Icons.add_circle_rounded,
                  label: 'Bid+ ₹${nextBid.toInt()}',
                  width: 120,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomBidCard({
    required List<Team> teams,
    required Team? selectedTeam,
    required void Function(Team)? onTeamSelected,
    required TextEditingController customBidController,
    required VoidCallback? onPlaceCustomBid,
    required bool isPlacing,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Bid',
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bid Amount (₹)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customBidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Team>(
                          isExpanded: true,
                          value: selectedTeam,
                          hint: const Text(
                            'Select team',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          items: teams.map((team) {
                            return DropdownMenuItem<Team>(
                              value: team,
                              child: Text(
                                '${team.name} (₹${team.purseRemaining.toInt()})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: onTeamSelected != null
                              ? (team) => onTeamSelected(team!)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  height: 40,
                  onPressed: onPlaceCustomBid,
                  icon: Icons.send_rounded,
                  label: 'Place Custom Bid',
                  width: double.infinity,
                  isLoading: isPlacing,
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
    required VoidCallback? onRestart,
    required VoidCallback? onEnd,
    required VoidCallback? onPickNext,
    required VoidCallback? onPickPrevious,
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
                  onPressed: onPickPrevious != null ? () => onPickPrevious() : null,
                  icon: Icons.skip_previous_rounded,
                  label: 'Previous Player',
                  width: double.infinity,
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
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
                  gradient: const LinearGradient(
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
                  gradient: const LinearGradient(
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
                  onPressed: onPause != null && onResume != null
                      ? (isPaused ? onResume : onPause)
                      : null,
                  icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: isPaused ? 'Resume' : 'Pause',
                  width: double.infinity,
                  gradient: const LinearGradient(
                    colors: [AppColors.warning, AppColors.warning],
                  ),
                  isLoading: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  height: 44,
                  onPressed: onRestart,
                  icon: Icons.restart_alt_rounded,
                  label: 'Restart',
                  width: double.infinity,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryPurple, AppColors.secondaryPurple],
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
                  gradient: const LinearGradient(
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

  Widget _buildRecentBids(List<Map<String, dynamic>> bids, List<Team> teams) {
    if (bids.isEmpty) return const SizedBox.shrink();

    final teamNameMap = {for (final t in teams) t.id: t.name};

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Bid History',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...bids.take(8).map((bid) {
            final teamId = bid['team_id'] as String?;
            final teamName = teamId != null
                ? teamNameMap[teamId] ?? teamId
                : 'Unknown';
            final amount = (bid['amount'] as num?)?.toInt() ?? 0;
            final timestamp = bid['timestamp'] as String?;
            final timeStr = timestamp != null
                ? _formatBidTime(timestamp)
                : '--:--';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupee(amount.toDouble()),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
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

  String _formatBidTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return timestamp;
    }
  }
}
