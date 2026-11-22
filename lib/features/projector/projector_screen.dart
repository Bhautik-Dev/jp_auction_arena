import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/live_state_provider.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/models.dart';

class ProjectorScreen extends ConsumerStatefulWidget {
  const ProjectorScreen({super.key});

  @override
  ConsumerState<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends ConsumerState<ProjectorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  String _lastSoldStatus = '';
  String _lastPlayerId = '';
  bool _showSoldUnsoldBanner = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerSoldUnsoldBanner(String playerId, String status) {
    if (_lastPlayerId != playerId || _lastSoldStatus != status) {
      _lastPlayerId = playerId;
      _lastSoldStatus = status;
      setState(() => _showSoldUnsoldBanner = true);
      _animController.forward(from: 0.0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSoldUnsoldBanner = false);
      });
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
    final auctionStatus = auctionState['status'] as String?;
    final currentBid = auctionState['current_bid_amount'] as double?;
    final bidCount = auctionState['bid_count'] as int? ?? 0;

    if (currentPlayer != null && currentPlayer.id != _lastPlayerId) {
      if (currentPlayer.status == PlayerStatus.sold) {
        _triggerSoldUnsoldBanner(currentPlayer.id, 'sold');
      } else if (currentPlayer.status == PlayerStatus.unsold) {
        _triggerSoldUnsoldBanner(currentPlayer.id, 'unsold');
      }
      _lastPlayerId = currentPlayer.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050A1A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050A1A), Color(0xFF0D1432)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLandscape(context)
              ? _buildLandscapeLayout(
                  context,
                  state,
                  auctionState,
                  currentPlayer,
                  leadingTeam,
                  players,
                  teams,
                  recentBids,
                  secondsRemaining,
                  isLive,
                  isPaused,
                  currentBid,
                  bidCount,
                  auctionStatus,
                )
              : _buildPortraitLayout(
                  context,
                  state,
                  auctionState,
                  currentPlayer,
                  leadingTeam,
                  players,
                  teams,
                  recentBids,
                  secondsRemaining,
                  isLive,
                  isPaused,
                  currentBid,
                  bidCount,
                  auctionStatus,
                ),
        ),
      ),
    );
  }

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  Widget _buildLandscapeLayout(
    BuildContext context,
    LiveAuctionState state,
    Map<String, dynamic> auctionState,
    Player? currentPlayer,
    Team? leadingTeam,
    List<Player> players,
    List<Team> teams,
    List<Map<String, dynamic>> recentBids,
    int secondsRemaining,
    bool isLive,
    bool isPaused,
    double? currentBid,
    int bidCount,
    String? auctionStatus,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildMainSpotlight(
            currentPlayer: currentPlayer,
            currentBid: currentBid,
            leadingTeam: leadingTeam,
            teams: teams,
            secondsRemaining: secondsRemaining,
            isLive: isLive,
            isPaused: isPaused,
            bidCount: bidCount,
            auctionStatus: auctionStatus,
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.cardBorder),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProjectorHeader(auctionState),
              const SizedBox(height: 20),
              _buildBidInfoCard(
                currentBid: currentBid,
                leadingTeam: leadingTeam,
                teams: teams,
                bidCount: bidCount,
              ),
              const SizedBox(height: 20),
              _buildTeamPursesCard(teams),
              const SizedBox(height: 20),
              _buildBidHistoryCard(recentBids, teams),
              const SizedBox(height: 20),
              _buildNextPlayerCard(currentPlayer, teams),
              const Spacer(),
              _buildConnectionStatusCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    LiveAuctionState state,
    Map<String, dynamic> auctionState,
    Player? currentPlayer,
    Team? leadingTeam,
    List<Player> players,
    List<Team> teams,
    List<Map<String, dynamic>> recentBids,
    int secondsRemaining,
    bool isLive,
    bool isPaused,
    double? currentBid,
    int bidCount,
    String? auctionStatus,
  ) {
    return Column(
      children: [
        _buildProjectorHeader(auctionState),
        const SizedBox(height: 20),
        Expanded(
          child: _buildMainSpotlight(
            currentPlayer: currentPlayer,
            currentBid: currentBid,
            leadingTeam: leadingTeam,
            teams: teams,
            secondsRemaining: secondsRemaining,
            isLive: isLive,
            isPaused: isPaused,
            bidCount: bidCount,
            auctionStatus: auctionStatus,
          ),
        ),
        const SizedBox(height: 20),
        _buildBidInfoCard(
          currentBid: currentBid,
          leadingTeam: leadingTeam,
          teams: teams,
          bidCount: bidCount,
        ),
        const SizedBox(height: 10),
        _buildTeamPursesCard(teams),
        const SizedBox(height: 10),
        _buildBidHistoryCard(recentBids, teams),
        const SizedBox(height: 10),
        _buildNextPlayerCard(currentPlayer, teams),
        const SizedBox(height: 10),
        _buildConnectionStatusCard(),
      ],
    );
  }

  Widget _buildProjectorHeader(Map<String, dynamic> auctionState) {
    final isLive = auctionState['is_live'] == true;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JP CRICKET AUCTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  isLive ? 'LIVE ON STAGE' : 'STANDBY',
                  style: TextStyle(
                    color: isLive ? AppColors.statusLive : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isLive ? AppColors.statusLive : AppColors.textMuted)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLive ? AppColors.statusLive : AppColors.textMuted,
                width: 1,
              ),
            ),
            child: Text(
              isLive ? 'LIVE' : 'OFF',
              style: TextStyle(
                color: isLive ? AppColors.statusLive : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSpotlight({
    required Player? currentPlayer,
    required double? currentBid,
    required Team? leadingTeam,
    required List<Team> teams,
    required int secondsRemaining,
    required bool isLive,
    required bool isPaused,
    required int bidCount,
    required String? auctionStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_showSoldUnsoldBanner)
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: _lastSoldStatus == 'sold'
                        ? AppColors.statusSold.withValues(alpha: 0.9)
                        : AppColors.statusUnsold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (_lastSoldStatus == 'sold'
                                ? AppColors.statusSold
                                : AppColors.statusUnsold)
                            .withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _lastSoldStatus == 'sold'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _lastSoldStatus == 'sold' ? 'SOLD!' : 'UNSOLD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showSoldUnsoldBanner) const SizedBox(height: 40),
          if (!isLive && auctionStatus == 'completed') _buildEndedState(),
          if (isPaused) _buildPausedState(),
          if (currentPlayer != null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildPlaceholderAvatar(currentPlayer.name),
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '#${currentPlayer.playerNo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentPlayer.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentPlayer.category.toUpperCase()}  •  ${currentPlayer.battingStyle.toUpperCase()}  •  ${currentPlayer.bowlingStyle.toUpperCase()}',
                          style: TextStyle(
                            color: AppColors.accentPink.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildSpotlightStat('MATCHES', '${currentPlayer.matches}'),
                            const SizedBox(width: 32),
                            _buildSpotlightStat('RUNS', '${currentPlayer.runs}'),
                            const SizedBox(width: 32),
                            _buildSpotlightStat('WICKETS', '${currentPlayer.wickets}'),
                            const SizedBox(width: 32),
                            _buildSpotlightStat('S.R.', currentPlayer.strikeRate.toStringAsFixed(0)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.statusLive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.statusLive,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${secondsRemaining}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'CURRENT BID',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentBid != null ? formatRupee(currentBid) : '--',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                if (leadingTeam != null) ...[
                  Text(
                    'Leading: ${leadingTeam.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (currentPlayer == null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_cricket_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'JP AUCTION ARENA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Auction is not currently live.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.stop_rounded,
          size: 80,
          color: AppColors.error,
        ),
        const SizedBox(height: 24),
        Text(
          'AUCTION COMPLETED',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No further bidding is possible.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPausedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.pause_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PAUSED',
          style: const TextStyle(
            color: AppColors.warning,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Auction is temporarily paused.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBidInfoCard({
    required double? currentBid,
    required Team? leadingTeam,
    required List<Team> teams,
    required int bidCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BIDDING',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$bidCount bids',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Bid',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentBid != null
                          ? formatRupee(currentBid)
                          : '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leading Team',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leadingTeam?.name ?? '--',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildTeamPursesCard(List<Team> teams) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEAM PURSES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: teams.take(6).map((t) {
              final remaining = t.purseRemaining;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.name.length > 8 ? '${t.name.substring(0, 8)}..' : t.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${remaining.toInt()}',
                      style: TextStyle(
                        color: remaining > 0 ? AppColors.gold : AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPlayerCard(Player? nextPlayer, List<Team> teams) {
    if (nextPlayer == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEXT PLAYER',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No players in queue',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT PLAYER',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceHighlight,
                ),
                child: ClipOval(
                  child: nextPlayer.photoBase64 != null &&
                          nextPlayer.photoBase64!.isNotEmpty
                      ? _buildMemoryImage(nextPlayer.photoBase64!)
                      : _buildPlaceholderAvatar(nextPlayer.name),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextPlayer.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${nextPlayer.playerNo}  •  ${nextPlayer.category}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupee(nextPlayer.basePrice),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildBidHistoryCard(List<Map<String, dynamic>> bids, List<Team> teams) {
    if (bids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE BID HISTORY',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No bids yet',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    final teamNameMap = {for (final t in teams) t.id: t.name};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE BID HISTORY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${bids.length} bids',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bids.take(6).map((bid) {
            final teamId = bid['team_id'] as String?;
            final teamName = teamId != null
                ? teamNameMap[teamId] ?? teamId
                : 'Unknown';
            final amount = (bid['amount'] as num?)?.toInt() ?? 0;
            final timestamp = bid['timestamp'] as String?;
            final timeStr = timestamp != null ? _formatBidTime(timestamp) : '--:--';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
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
                          teamName.length > 12 ? '${teamName.substring(0, 12)}..' : teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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

  Widget _buildConnectionStatusCard() {
    final client = SupabaseClientService.instance.client;
    final connected = client != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: connected ? AppColors.statusSold.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected ? AppColors.statusSold : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected ? AppColors.statusSold : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              connected ? 'LIVE FEED ACTIVE' : 'LIVE FEED DISCONNECTED',
              style: TextStyle(
                color: connected ? AppColors.statusSold : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          if (!connected)
            Text(
              'RECONNECTING...',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoryImage(String base64) {
    try {
      final bytes = base64Decode(base64);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar('?'),
      );
    } catch (_) {
      return _buildPlaceholderAvatar('?');
    }
  }

  Widget _buildPlaceholderAvatar(String name) {
    return Container(
      color: AppColors.surfaceHighlight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
