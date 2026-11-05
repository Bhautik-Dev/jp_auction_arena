import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];

    final soldPlayers = players.where((p) => p.status == PlayerStatus.sold).toList();
    final totalSpent = soldPlayers.fold<double>(0.0, (acc, p) => acc + (p.soldPrice ?? 0.0));
    final avgSoldPrice = soldPlayers.isNotEmpty ? totalSpent / soldPlayers.length : 0.0;

    return FeaturePlaceholderScreen(
      title: 'Auction Analytics & Insights',
      description: activeAuction != null
          ? 'Purse utilization, category demand, and valuation metrics for "${activeAuction.name}"'
          : 'Purse utilization, category demand, and valuation metrics',
      icon: Icons.analytics_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Capital Traded', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatShort(totalSpent),
                      style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.formatInr(totalSpent),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Average Player Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatShort(avgSoldPrice),
                      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Across ${soldPlayers.length} sold players',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clearance Rate', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      players.isNotEmpty
                          ? '${((soldPlayers.length / players.length) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: const TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${players.length - soldPlayers.length} remaining or unsold',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Team Spending Leaderboard', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (teams.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No team analytics available yet.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...teams.map((t) {
            final share = t.purseTotal > 0 ? (t.purseSpent / t.purseTotal).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(
                          '${CurrencyFormatter.formatShort(t.purseSpent)} / ${CurrencyFormatter.formatShort(t.purseTotal)} (${(share * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: AppColors.accentPink, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: share,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
