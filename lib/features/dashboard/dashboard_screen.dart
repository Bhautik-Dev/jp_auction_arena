import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isRefreshing = false;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update countdown timer every second for auction countdown card
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Refresh providers
    ref.invalidate(auctionsListProvider);
    ref.invalidate(currentAuctionTeamsProvider);
    ref.invalidate(currentAuctionPlayersProvider);
    ref.invalidate(allTeamsListProvider);
    ref.invalidate(allPlayersListProvider);
    ref.invalidate(allBidsListProvider);
    ref.read(authProvider.notifier).refresh();

    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard stats refreshed from local Hive database!'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileName = authState.settings.profileName.isNotEmpty
        ? authState.settings.profileName
        : 'Auctioneer';

    final auctionsAsync = ref.watch(auctionsListProvider);
    final allAuctions = auctionsAsync.value ?? [];
    final activeAuction = ref.watch(activeAuctionProvider);
    final activeId = ref.watch(activeAuctionIdProvider);

    // Filtered data based on chosen auction (or all if none/all selected)
    final allTeams = ref.watch(allTeamsListProvider).value ?? [];
    final allPlayers = ref.watch(allPlayersListProvider).value ?? [];

    final displayedTeams = activeAuction != null
        ? allTeams.where((t) => t.auctionId == activeAuction.id).toList()
        : allTeams;

    final displayedPlayers = activeAuction != null
        ? allPlayers.where((p) => p.auctionId == activeAuction.id).toList()
        : allPlayers;

    final isLoading = _isRefreshing || auctionsAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Banner & Auction Selector Dropdown
            _buildHeader(
              context: context,
              profileName: profileName,
              allAuctions: allAuctions,
              activeAuction: activeAuction,
              activeId: activeId,
            ),
            const SizedBox(height: 24),

            // 2. 6 Stat Cards (Animated Count-Up & Shimmer)
            _buildSixStatCards(
              isLoading: isLoading,
              allAuctions: allAuctions,
              displayedTeams: displayedTeams,
              displayedPlayers: displayedPlayers,
              isFilteredByAuction: activeAuction != null,
            ),
            const SizedBox(height: 24),

            // 3. Highlight Row: Highest Bid Today & Next Scheduled Auction Countdown
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 840;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildHighestBidCard(
                              isLoading: isLoading,
                              players: displayedPlayers,
                              teams: displayedTeams,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildNextAuctionCountdownCard(
                              isLoading: isLoading,
                              allAuctions: allAuctions,
                              activeAuction: activeAuction,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildHighestBidCard(
                            isLoading: isLoading,
                            players: displayedPlayers,
                            teams: displayedTeams,
                          ),
                          const SizedBox(height: 20),
                          _buildNextAuctionCountdownCard(
                            isLoading: isLoading,
                            allAuctions: allAuctions,
                            activeAuction: activeAuction,
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),

            // 4. Quick Action Tiles
            _buildQuickActionTiles(context),
            const SizedBox(height: 24),

            // 5. Team Purse Usage & Recent Activity
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTeamPurseUsageCard(
                              isLoading: isLoading,
                              teams: displayedTeams,
                              activeAuction: activeAuction,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildRecentActivityCard(
                              isLoading: isLoading,
                              players: displayedPlayers,
                              teams: displayedTeams,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildTeamPurseUsageCard(
                            isLoading: isLoading,
                            teams: displayedTeams,
                            activeAuction: activeAuction,
                          ),
                          const SizedBox(height: 20),
                          _buildRecentActivityCard(
                            isLoading: isLoading,
                            players: displayedPlayers,
                            teams: displayedTeams,
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER WITH GREETING & AUCTION SELECTOR
  // ==========================================
  Widget _buildHeader({
    required BuildContext context,
    required String profileName,
    required List<Auction> allAuctions,
    required Auction? activeAuction,
    required String? activeId,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E2852),
            Color(0xFF141B3A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_cricket_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $profileName 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JP AUCTION ARENA • Offline Cricket Auction Command Hub',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Refresh button
              IconButton(
                onPressed: _isRefreshing ? null : _handleRefresh,
                tooltip: 'Refresh Stats',
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create Auction Button
              GradientButton(
                onPressed: () => context.go(RouteNames.createAuctionPath),
                icon: Icons.add_rounded,
                label: 'Create Auction',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Auction Selector Dropdown Filter
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_outlined, color: AppColors.accentPink, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Filter by Auction:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: activeAuction?.id,
                      dropdownColor: AppColors.card,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.accentPink),
                      hint: const Text(
                        'All Tournaments (Global View)',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            '🌐 All Tournaments (Global View)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...allAuctions.map((a) {
                          final isCurrentActive = activeAuction?.id == a.id;
                          return DropdownMenuItem<String?>(
                            value: a.id,
                            child: Row(
                              children: [
                                Text(
                                  a.name,
                                  style: TextStyle(
                                    color: isCurrentActive ? AppColors.accentPink : Colors.white,
                                    fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (a.status == AuctionStatus.live
                                            ? AppColors.error
                                            : AppColors.primaryBlue)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    a.status.displayName,
                                    style: TextStyle(
                                      color: a.status == AuctionStatus.live
                                          ? AppColors.error
                                          : AppColors.primaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        ref.read(activeAuctionIdProvider.notifier).setAuctionId(val);
                      },
                    ),
                  ),
                ),
              ),
              if (activeAuction != null) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(activeAuctionIdProvider.notifier).setAuctionId(null);
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Show All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. 6 STAT CARDS WITH ANIMATED COUNT-UP
  // ==========================================
  Widget _buildSixStatCards({
    required bool isLoading,
    required List<Auction> allAuctions,
    required List<Team> displayedTeams,
    required List<Player> displayedPlayers,
    required bool isFilteredByAuction,
  }) {
    final totalAuctions = allAuctions.length;
    final activeAuctionsCount =
        allAuctions.where((a) => a.status == AuctionStatus.live).length;
    final totalTeamsCount = displayedTeams.length;
    final totalPlayersCount = displayedPlayers.length;

    final soldPlayers =
        displayedPlayers.where((p) => p.status == PlayerStatus.sold).toList();
    final soldCount = soldPlayers.length;
    final soldPercentage = totalPlayersCount > 0
        ? ((soldCount / totalPlayersCount) * 100).toStringAsFixed(1)
        : '0.0';

    // Total Auction Value: sum of sold player prices
    final totalAuctionValue = soldPlayers.fold<double>(
      0.0,
      (acc, p) => acc + (p.soldPrice ?? 0.0),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1050
            ? 6
            : (constraints.maxWidth >= 720
                ? 3
                : (constraints.maxWidth >= 480 ? 2 : 1));

        final spacing = 16.0;
        final totalSpacing = (crossAxisCount - 1) * spacing;
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Total Auctions',
              countValue: totalAuctions,
              subtitle: 'All created tournaments',
              icon: Icons.emoji_events_rounded,
              accentColor: AppColors.primaryBlue,
            ),
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Active Auctions',
              countValue: activeAuctionsCount,
              subtitle: '$activeAuctionsCount live in arena',
              icon: Icons.play_circle_fill_rounded,
              accentColor: AppColors.statusLive,
            ),
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Total Teams',
              countValue: totalTeamsCount,
              subtitle: isFilteredByAuction ? 'Competing franchise teams' : 'Across all auctions',
              icon: Icons.groups_rounded,
              accentColor: AppColors.secondaryPurple,
            ),
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Total Players',
              countValue: totalPlayersCount,
              subtitle: 'Registered cricketers',
              icon: Icons.person_search_rounded,
              accentColor: AppColors.accentPink,
            ),
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Players Sold',
              countValue: soldCount,
              subtitle: '$soldPercentage% of registered pool',
              icon: Icons.how_to_reg_rounded,
              accentColor: AppColors.success,
              valueSuffix: ' ($soldPercentage%)',
            ),
            _buildStatCard(
              width: itemWidth,
              isLoading: isLoading,
              title: 'Total Auction Value',
              countValue: totalAuctionValue,
              customDisplayValue: formatShort(totalAuctionValue),
              subtitle: formatRupee(totalAuctionValue),
              icon: Icons.currency_rupee_rounded,
              accentColor: AppColors.gold,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required bool isLoading,
    required String title,
    required num countValue,
    String? customDisplayValue,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    String valueSuffix = '',
  }) {
    return SizedBox(
      width: width,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: ShimmerLoading(
          isLoading: isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (customDisplayValue != null)
                Text(
                  customDisplayValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                CountUpText(
                  value: countValue,
                  suffix: valueSuffix,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. HIGHEST BID TODAY & COUNTDOWN CARDS
  // ==========================================
  Widget _buildHighestBidCard({
    required bool isLoading,
    required List<Player> players,
    required List<Team> teams,
  }) {
    // Find player with the highest sold price
    Player? highestPlayer;
    double maxPrice = 0.0;

    for (final p in players) {
      if (p.status == PlayerStatus.sold && p.soldPrice != null && p.soldPrice! > maxPrice) {
        maxPrice = p.soldPrice!;
        highestPlayer = p;
      }
    }

    Team? soldTeam;
    if (highestPlayer != null && highestPlayer.soldTeamId != null) {
      soldTeam = teams.firstWhere(
        (t) => t.id == highestPlayer!.soldTeamId,
        orElse: () => Team(
          id: '',
          auctionId: '',
          name: 'Franchise',
          purseTotal: 0,
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      hasGlow: true,
      child: ShimmerLoading(
        isLoading: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: AppColors.gold, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'HIGHEST BID OF THE TOURNAMENT',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'RECORD BUY',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (highestPlayer == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.gavel_rounded, color: AppColors.textMuted, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No hammer sales yet',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Start the live auction to record bids and top sales.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: Text(
                      '#${highestPlayer.playerNo}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          highestPlayer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${highestPlayer.category} • Sold to ${soldTeam?.name ?? "Team"}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatShort(maxPrice),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        formatRupee(maxPrice),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextAuctionCountdownCard({
    required bool isLoading,
    required List<Auction> allAuctions,
    required Auction? activeAuction,
  }) {
    // Find next upcoming auction (draft or live or future date)
    Auction? nextAuction;
    final futureAuctions = allAuctions
        .where((a) => a.startDateTime.isAfter(_now) || a.status != AuctionStatus.completed)
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    if (futureAuctions.isNotEmpty) {
      nextAuction = futureAuctions.first;
    } else if (activeAuction != null) {
      nextAuction = activeAuction;
    }

    final Duration diff = nextAuction != null
        ? nextAuction.startDateTime.difference(_now)
        : Duration.zero;

    final isPast = diff.isNegative;
    final absDiff = diff.abs();

    final days = absDiff.inDays;
    final hours = absDiff.inHours % 24;
    final minutes = absDiff.inMinutes % 60;
    final seconds = absDiff.inSeconds % 60;

    return GlassCard(
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
      hasGlow: true,
      child: ShimmerLoading(
        isLoading: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined,
                          color: AppColors.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AUCTION COUNTDOWN',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPast ? AppColors.statusLive : AppColors.primaryBlue)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPast ? AppColors.statusLive : AppColors.primaryBlue,
                    ),
                  ),
                  child: Text(
                    isPast ? 'IN PROGRESS' : 'UPCOMING',
                    style: TextStyle(
                      color: isPast ? AppColors.statusLive : AppColors.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (nextAuction == null) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No scheduled auctions found. Create one now!',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ] else ...[
              Text(
                nextAuction.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                nextAuction.venue.isNotEmpty
                    ? 'Venue: ${nextAuction.venue}'
                    : 'Scheduled Auction Arena',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              // Countdown timers blocks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCountdownBlock('$days', 'DAYS'),
                  const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildCountdownBlock(hours.toString().padLeft(2, '0'), 'HOURS'),
                  const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildCountdownBlock(minutes.toString().padLeft(2, '0'), 'MINS'),
                  const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildCountdownBlock(seconds.toString().padLeft(2, '0'), 'SECS'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. QUICK ACTION TILES
  // ==========================================
  Widget _buildQuickActionTiles(BuildContext context) {
    final actions = [
      _ActionTileData(
        title: 'Create Auction',
        subtitle: 'Setup tournament rules & purse',
        icon: Icons.add_circle_outline_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        onTap: () => context.go(RouteNames.createAuctionPath),
      ),
      _ActionTileData(
        title: 'Manage Teams',
        subtitle: 'Franchise purse & squads',
        icon: Icons.groups_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        onTap: () => context.go(RouteNames.teamsPath),
      ),
      _ActionTileData(
        title: 'Manage Players',
        subtitle: 'Cricket pool, stats & base price',
        icon: Icons.person_search_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
        ),
        onTap: () => context.go(RouteNames.playersPath),
      ),
      _ActionTileData(
        title: 'Go Live',
        subtitle: 'Enter live hammer bidding arena',
        icon: Icons.gavel_rounded,
        gradient: AppColors.buttonGradient,
        onTap: () => context.go(RouteNames.livePath),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 540 ? 2 : 1);

        final spacing = 16.0;
        final totalSpacing = (crossAxisCount - 1) * spacing;
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((act) {
            return SizedBox(
              width: itemWidth,
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                onTap: act.onTap,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: act.gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(act.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            act.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==========================================
  // 5. TEAM PURSE USAGE (PROGRESS BAR & LOGO)
  // ==========================================
  Widget _buildTeamPurseUsageCard({
    required bool isLoading,
    required List<Team> teams,
    required Auction? activeAuction,
  }) {
    return GlassCard(
      child: ShimmerLoading(
        isLoading: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'TEAM PURSE USAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${teams.length} Franchises',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (teams.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No teams registered for this tournament yet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final fractionSpent = team.purseTotal > 0
                      ? (team.purseSpent / team.purseTotal).clamp(0.0, 1.0)
                      : 0.0;
                  final percent = (fractionSpent * 100).toStringAsFixed(1);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Team Logo / Avatar with gradient background
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue.withValues(alpha: 0.8),
                                    AppColors.secondaryPurple.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  team.name.isNotEmpty
                                      ? team.name[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Squad: ${team.squadCount} Players',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${formatShort(team.purseSpent)} / ${formatShort(team.purseTotal)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Left: ${formatShort(team.purseRemaining)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Gradient Progress Bar
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: fractionSpent,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: AppColors.buttonGradient,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentPink.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$percent% purse spent',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. RECENT ACTIVITY (LAST 10 SOLD/UNSOLD)
  // ==========================================
  Widget _buildRecentActivityCard({
    required bool isLoading,
    required List<Player> players,
    required List<Team> teams,
  }) {
    // Collect sold or unsold players
    final resolvedPlayers = players
        .where((p) => p.status == PlayerStatus.sold || p.status == PlayerStatus.unsold)
        .toList();

    // Take last 10 events
    final recentEvents = resolvedPlayers.reversed.take(10).toList();

    return GlassCard(
      child: ShimmerLoading(
        isLoading: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.accentPink, size: 20),
                SizedBox(width: 8),
                Text(
                  'RECENT ACTIVITY (LAST 10)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No auction events yet',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sold and unsold players will appear here in real-time.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentEvents.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final player = recentEvents[index];
                  final isSold = player.status == PlayerStatus.sold;

                  Team? soldTeam;
                  if (isSold && player.soldTeamId != null) {
                    soldTeam = teams.firstWhere(
                      (t) => t.id == player.soldTeamId,
                      orElse: () => Team(
                        id: '',
                        auctionId: '',
                        name: 'Team',
                        purseTotal: 0,
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isSold ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isSold ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 16,
                          color: isSold ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isSold
                                  ? 'Acquired by ${soldTeam?.name ?? "Team"}'
                                  : 'Passed hammer • Marked Unsold',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isSold
                                ? formatShort(player.soldPrice ?? 0)
                                : 'UNSOLD',
                            style: TextStyle(
                              color: isSold ? AppColors.gold : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (isSold ? AppColors.success : AppColors.textMuted)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSold ? 'SOLD' : 'UNSOLD',
                              style: TextStyle(
                                color: isSold ? AppColors.success : AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  _ActionTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
