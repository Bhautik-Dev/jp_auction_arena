import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class AuctionsScreen extends ConsumerWidget {
  const AuctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(auctionsListProvider);
    final activeAuction = ref.watch(activeAuctionProvider);

    return FeaturePlaceholderScreen(
      title: 'Tournaments & Auctions',
      description: 'Manage cricket tournaments, rules, and purse allocations',
      icon: Icons.emoji_events_rounded,
      actionButton: GradientButton(
        onPressed: () => context.go('/create-auction'),
        icon: Icons.add_rounded,
        label: 'New Auction',
      ),
      children: [
        auctionsAsync.when(
          data: (auctions) {
            if (auctions.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No Auctions Created Yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first tournament to start assigning teams and players.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        onPressed: () => context.go('/create-auction'),
                        icon: Icons.add_rounded,
                        label: 'Create Tournament',
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auctions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final auction = auctions[index];
                final isActive = activeAuction?.id == auction.id;

                return GlassCard(
                  borderColor: isActive ? AppColors.accentPink : null,
                  hasGlow: isActive,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                auction.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPink.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.accentPink),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: AppColors.accentPink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auction.status.displayName,
                              style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildDetail(Icons.location_on_outlined, auction.venue.isNotEmpty ? auction.venue : 'Unspecified Venue'),
                          _buildDetail(Icons.groups_outlined, '${auction.numberOfTeams} Teams (${auction.minSquad}-${auction.maxSquad} players)'),
                          _buildDetail(Icons.currency_rupee_rounded, 'Purse: ${CurrencyFormatter.formatShort(auction.teamPurse)}'),
                          _buildDetail(Icons.timer_outlined, '${auction.countdownSeconds}s Hammer Timer'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!isActive)
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.read(activeAuctionIdProvider.notifier).setAuctionId(auction.id);
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Set as Active'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => context.go('/live'),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text('Live Auction'),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Delete Auction',
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Auction?'),
                                  content: Text('Are you sure you want to delete "${auction.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(auctionRepositoryProvider).delete(auction.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
