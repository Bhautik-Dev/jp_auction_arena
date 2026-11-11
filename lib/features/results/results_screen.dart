import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];

    final soldPlayers = players.where((p) => p.status == PlayerStatus.sold).toList();
    final unsoldPlayers = players.where((p) => p.status == PlayerStatus.unsold).toList();

    return FeaturePlaceholderScreen(
      title: 'Auction Results',
      description: activeAuction != null
          ? 'Sold vs unsold summaries, squad lists, and sale ledgers for "${activeAuction.name}"'
          : 'Sold vs unsold summaries, squad lists, and sale ledgers',
      icon: Icons.checklist_rounded,
      children: [
        // Summary cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final itemWidth = isCompact ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 32) / 3;

            Widget buildCard(String title, String val, Color color) {
              return SizedBox(
                width: isCompact && title == 'Top Sale' ? constraints.maxWidth : itemWidth,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        val,
                        style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }

            final topSaleVal = soldPlayers.isEmpty
                ? '₹0'
                : CurrencyFormatter.formatShort(
                    soldPlayers.map((p) => p.soldPrice ?? 0).reduce((a, b) => a > b ? a : b),
                  );

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildCard('Total Sold', '${soldPlayers.length}', AppColors.success),
                buildCard('Unsold Players', '${unsoldPlayers.length}', AppColors.error),
                buildCard('Top Sale', topSaleVal, AppColors.gold),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Final Squads by Team', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (teams.isEmpty)
          const GlassCard(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No teams to display results for.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...teams.map((t) {
            final teamSoldPlayers = soldPlayers.where((p) => p.soldTeamId == t.id).toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Spent: ${CurrencyFormatter.formatShort(t.purseSpent)} | Remaining: ${CurrencyFormatter.formatShort(t.purseRemaining)}',
                          style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (teamSoldPlayers.isEmpty)
                      const Text('No players purchased yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: teamSoldPlayers.map((p) {
                          return Chip(
                            backgroundColor: AppColors.surfaceLight,
                            label: Text(
                              '${p.name} (${CurrencyFormatter.formatShort(p.soldPrice ?? 0)})',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          );
                        }).toList(),
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
