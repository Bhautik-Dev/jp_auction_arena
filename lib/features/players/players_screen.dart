import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final playersAsync = ref.watch(currentAuctionPlayersProvider);

    return FeaturePlaceholderScreen(
      title: 'Players Pool',
      description: activeAuction != null
          ? 'Player registrations for "${activeAuction.name}"'
          : 'Select an auction to view player pool',
      icon: Icons.person_search_rounded,
      actionButton: GradientButton(
        onPressed: () => context.go('/registration'),
        icon: Icons.person_add_alt_1_rounded,
        label: 'Register Player',
      ),
      children: [
        playersAsync.when(
          data: (players) {
            if (players.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No Players Registered',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register cricketers with stats, base prices, and categories.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        onPressed: () => context.go('/registration'),
                        icon: Icons.person_add_rounded,
                        label: 'Register First Player',
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = players[index];
                Color badgeColor = AppColors.primaryBlue;
                if (p.status == PlayerStatus.sold) badgeColor = AppColors.success;
                if (p.status == PlayerStatus.unsold) badgeColor = AppColors.textMuted;
                if (p.status == PlayerStatus.live) badgeColor = AppColors.error;

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceLight,
                        child: Text(
                          '#${p.playerNo}',
                          style: const TextStyle(
                            color: AppColors.accentPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.isIcon)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ICON',
                                      style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.category} • ${p.battingStyle} • ${p.village.isNotEmpty ? p.village : "Local"}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatShort(p.basePrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              p.status.displayName,
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        onPressed: () async {
                          final confirm = await AppConfirmDialog.show(
                            context,
                            title: 'Delete Player',
                            content: 'Are you sure you want to remove "${p.name}" (#${p.playerNo}) from this auction pool?',
                            confirmText: 'Delete',
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            await ref.read(playerRepositoryProvider).delete(p.id);
                            if (context.mounted) {
                              AppToast.showSuccess(context, 'Player "${p.name}" deleted.');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => Column(
            children: List.generate(
              4,
              (i) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: AppSkeleton.card(height: 72),
              ),
            ),
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Players',
            description: e.toString(),
            action: ElevatedButton.icon(
              onPressed: () => ref.invalidate(currentAuctionPlayersProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ),
      ],
    );
  }
}
