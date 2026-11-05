import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class ProjectorScreen extends ConsumerWidget {
  const ProjectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final availablePlayers = players.where((p) => p.status == PlayerStatus.available).toList();
    final currentPlayer = availablePlayers.isNotEmpty ? availablePlayers.first : null;

    return FeaturePlaceholderScreen(
      title: 'Projector & TV Stage',
      description: 'Ultra-wide full screen display optimized for venue projectors and LED walls',
      icon: Icons.tv_rounded,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(32),
          borderColor: AppColors.primaryBlue,
          hasGlow: true,
          child: Column(
            children: [
              // Tournament Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeAuction?.name ?? 'JP CRICKET AUCTION',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        activeAuction?.venue ?? 'Grand Pavilion Stage',
                        style: const TextStyle(color: AppColors.accentPink, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'STAGE BROADCAST',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (currentPlayer == null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'WAITING FOR NEXT LOT TO TAKE THE STAGE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                // Main stage spotlight
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          '#${currentPlayer.playerNo}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPlayer.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ROLE: ${currentPlayer.category.toUpperCase()} • ${currentPlayer.battingStyle.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.accentPink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildBigStat('MATCHES', '${currentPlayer.matches}'),
                              const SizedBox(width: 24),
                              _buildBigStat('RUNS', '${currentPlayer.runs}'),
                              const SizedBox(width: 24),
                              _buildBigStat('WICKETS', '${currentPlayer.wickets}'),
                              const SizedBox(width: 24),
                              _buildBigStat('STRIKE RATE', '${currentPlayer.strikeRate}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'BASE PRICE',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1),
                        ),
                        Text(
                          CurrencyFormatter.formatInr(currentPlayer.basePrice),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),
              // Team purse grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TEAM PURSES REMAINING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${teams.length} Teams Competing', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: teams.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.formatShort(t.purseRemaining),
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBigStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
