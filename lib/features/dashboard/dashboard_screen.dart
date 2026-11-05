import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final auctionsAsync = ref.watch(auctionsListProvider);
    final teamsAsync = ref.watch(currentAuctionTeamsProvider);
    final playersAsync = ref.watch(currentAuctionPlayersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header banner
            _buildWelcomeHeader(context, activeAuction),
            const SizedBox(height: 24),

            // Quick Stats Grid
            _buildStatsOverview(
              activeAuction: activeAuction,
              teamsCount: teamsAsync.value?.length ?? 0,
              players: playersAsync.value ?? [],
            ),
            const SizedBox(height: 28),

            // Quick Actions & Active Auction Status
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildActiveAuctionCard(context, activeAuction),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildQuickActionsCard(context),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildActiveAuctionCard(context, activeAuction),
                          const SizedBox(height: 20),
                          _buildQuickActionsCard(context),
                        ],
                      );
              },
            ),
            const SizedBox(height: 28),

            // Recent Auctions summary
            _buildRecentAuctionsSection(context, auctionsAsync.value ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, Auction? activeAuction) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'JP AUCTION ARENA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentPink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentPink.withValues(alpha: 0.6)),
                      ),
                      child: const Text(
                        'OFFLINE FIRST',
                        style: TextStyle(
                          color: AppColors.accentPink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activeAuction != null
                      ? 'Active Tournament: ${activeAuction.name} • ${activeAuction.venue.isNotEmpty ? activeAuction.venue : "Local Venue"}'
                      : 'No tournament selected. Create or select an auction to start bidding.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GradientButton(
            onPressed: () => context.go('/live'),
            icon: Icons.play_arrow_rounded,
            label: 'Enter Live Arena',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview({
    required Auction? activeAuction,
    required int teamsCount,
    required List<Player> players,
  }) {
    final soldPlayers = players.where((p) => p.status == PlayerStatus.sold).length;
    final unsoldPlayers = players.where((p) => p.status == PlayerStatus.unsold).length;
    final availablePlayers = players.where((p) => p.status == PlayerStatus.available).length;
    final totalSpent = players
        .where((p) => p.status == PlayerStatus.sold && p.soldPrice != null)
        .fold<double>(0.0, (acc, p) => acc + (p.soldPrice ?? 0.0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 540 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              width: itemWidth,
              title: 'Total Teams',
              value: '$teamsCount',
              subtitle: 'Cap: ${activeAuction?.numberOfTeams ?? 8} teams',
              icon: Icons.groups_rounded,
              accentColor: AppColors.primaryBlue,
            ),
            _buildStatCard(
              width: itemWidth,
              title: 'Total Players',
              value: '${players.length}',
              subtitle: '$soldPlayers Sold • $unsoldPlayers Unsold',
              icon: Icons.person_rounded,
              accentColor: AppColors.secondaryPurple,
            ),
            _buildStatCard(
              width: itemWidth,
              title: 'Available in Pool',
              value: '$availablePlayers',
              subtitle: 'Awaiting hammer',
              icon: Icons.how_to_reg_rounded,
              accentColor: AppColors.accentPink,
            ),
            _buildStatCard(
              width: itemWidth,
              title: 'Total Spent',
              value: CurrencyFormatter.formatShort(totalSpent),
              subtitle: CurrencyFormatter.formatInr(totalSpent),
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
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return SizedBox(
      width: width,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
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
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAuctionCard(BuildContext context, Auction? auction) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE TOURNAMENT DETAILS',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (auction != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Text(
                    auction.status.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (auction == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No auction selected. Go to Auctions tab to create one.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ] else ...[
            Text(
              auction.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              auction.description.isNotEmpty
                  ? auction.description
                  : 'Local cricket tournament auction managed with JP AUCTION ARENA.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _buildInfoPill(
                  'Purse / Team',
                  CurrencyFormatter.formatInr(auction.teamPurse),
                ),
                _buildInfoPill(
                  'Default Base',
                  CurrencyFormatter.formatInr(auction.basePriceDefault),
                ),
                _buildInfoPill(
                  'Bid Step',
                  CurrencyFormatter.formatInr(auction.bidIncrement),
                ),
                _buildInfoPill(
                  'Squad Size',
                  '${auction.minSquad} - ${auction.maxSquad}',
                ),
                _buildInfoPill('Timer', '${auction.countdownSeconds}s'),
                _buildInfoPill('Mode', auction.mode.displayName),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/projector'),
                  icon: const Icon(Icons.tv_rounded, size: 16),
                  label: const Text('Launch Projector'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/teams'),
                  icon: const Icon(Icons.groups_rounded, size: 16),
                  label: const Text('Manage Teams'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK SHORTCUTS',
            style: TextStyle(
              color: AppColors.secondaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionRow(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create Auction',
            subtitle: 'Setup a new tournament',
            onTap: () => context.go('/create-auction'),
          ),
          const Divider(height: 16),
          _buildActionRow(
            icon: Icons.person_add_outlined,
            title: 'Register Players',
            subtitle: 'Bulk or single registration',
            onTap: () => context.go('/registration'),
          ),
          const Divider(height: 16),
          _buildActionRow(
            icon: Icons.assessment_outlined,
            title: 'Auction Analytics',
            subtitle: 'Spending trends & stats',
            onTap: () => context.go('/analytics'),
          ),
          const Divider(height: 16),
          _buildActionRow(
            icon: Icons.tv_rounded,
            title: 'Projector View',
            subtitle: 'Big screen live display',
            onTap: () => context.go('/projector'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
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
  }

  Widget _buildRecentAuctionsSection(BuildContext context, List<Auction> auctions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Tournaments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/auctions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (auctions.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Tournaments Created Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create your first cricket tournament auction to get started.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: () => context.go('/create-auction'),
                      icon: Icons.add_rounded,
                      label: 'Create Tournament',
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auctions.take(3).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = auctions[index];
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => context.go('/auctions'),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Icon(Icons.sports_cricket, color: AppColors.accentPink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Purse: ${CurrencyFormatter.formatInr(a.teamPurse)} • ${a.numberOfTeams} Teams',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        a.status.displayName,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
