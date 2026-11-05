import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final players = ref.watch(currentAuctionPlayersProvider).value ?? [];
    final teams = ref.watch(currentAuctionTeamsProvider).value ?? [];

    final availablePlayers = players.where((p) => p.status == PlayerStatus.available).toList();
    final currentPlayer = availablePlayers.isNotEmpty ? availablePlayers.first : null;

    return FeaturePlaceholderScreen(
      title: 'Live Auction Hammer Arena',
      description: activeAuction != null
          ? 'Live bidding desk for ${activeAuction.name}'
          : 'Please select an auction to start live hammer bidding',
      icon: Icons.gavel_rounded,
      actionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statusLive.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.statusLive),
            ),
            child: const Row(
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
                    'All players have been auctioned or no players are registered yet.',
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
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                      child: Text(
                        '#${currentPlayer.playerNo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentPlayer.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryPurple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentPlayer.category,
                                  style: const TextStyle(color: AppColors.secondaryPurple, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${currentPlayer.battingStyle} • ${currentPlayer.bowlingStyle} • Village: ${currentPlayer.village.isNotEmpty ? currentPlayer.village : "Local"}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Text(
                            '${activeAuction?.countdownSeconds ?? 30}s',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Bidding Pad & Quick Teams',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bid Step: +${CurrencyFormatter.formatShort(activeAuction?.bidIncrement ?? 2000)}',
                      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: teams.map((team) {
                    return ActionChip(
                      backgroundColor: AppColors.surfaceLight,
                      label: Text('${team.name} (${CurrencyFormatter.formatShort(team.purseRemaining)})'),
                      avatar: const Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.success),
                      onPressed: () {
                        // Place bid logic placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bid placed for ${team.name} on ${currentPlayer.name}!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        currentPlayer.status = PlayerStatus.unsold;
                        await ref.read(playerRepositoryProvider).save(currentPlayer);
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      child: const Text('Mark UNSOLD'),
                    ),
                    const SizedBox(width: 14),
                    GradientButton(
                      onPressed: teams.isEmpty
                          ? null
                          : () async {
                              final firstTeam = teams.first;
                              currentPlayer.status = PlayerStatus.sold;
                              currentPlayer.soldPrice = currentPlayer.basePrice;
                              currentPlayer.soldTeamId = firstTeam.id;
                              firstTeam.purseSpent += currentPlayer.basePrice;
                              firstTeam.playerIds.add(currentPlayer.id);

                              await ref.read(playerRepositoryProvider).save(currentPlayer);
                              await ref.read(teamRepositoryProvider).save(firstTeam);
                            },
                      icon: Icons.gavel_rounded,
                      label: 'Sold at Base Price',
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
