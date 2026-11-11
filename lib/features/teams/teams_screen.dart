import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/app_ui_feedback.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  void _showAddTeamDialog(BuildContext context, WidgetRef ref, Auction? activeAuction) {
    if (activeAuction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an active auction first.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final purseController = TextEditingController(text: activeAuction.teamPurse.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tournament Team'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Team Name', hintText: 'e.g. Royal Strikers'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(labelText: 'Owner / Captain Name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: purseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purse Allocation (₹)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            height: 40,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final team = Team(
                id: 'team_${DateTime.now().millisecondsSinceEpoch}',
                auctionId: activeAuction.id,
                name: name,
                ownerName: ownerController.text.trim(),
                purseTotal: double.tryParse(purseController.text.trim()) ?? activeAuction.teamPurse,
              );
              await ref.read(teamRepositoryProvider).save(team);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            label: 'Add Team',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAuction = ref.watch(activeAuctionProvider);
    final teamsAsync = ref.watch(currentAuctionTeamsProvider);

    return FeaturePlaceholderScreen(
      title: 'Teams Management',
      description: activeAuction != null
          ? 'Registered teams for "${activeAuction.name}"'
          : 'Create or select an auction to manage teams',
      icon: Icons.groups_rounded,
      actionButton: GradientButton(
        onPressed: () => _showAddTeamDialog(context, ref, activeAuction),
        icon: Icons.group_add_rounded,
        label: 'Add Team',
      ),
      children: [
        teamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined, size: 54, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No Teams Registered Yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add teams with their purse budgets to start bidding.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        onPressed: () => _showAddTeamDialog(context, ref, activeAuction),
                        icon: Icons.group_add_rounded,
                        label: 'Register First Team',
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                final width = (constraints.maxWidth - ((count - 1) * 16)) / count;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: teams.map((team) {
                    final percent = team.purseTotal > 0
                        ? (team.purseRemaining / team.purseTotal).clamp(0.0, 1.0)
                        : 0.0;

                    return SizedBox(
                      width: width,
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.25),
                                  child: Text(
                                    team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        team.ownerName.isNotEmpty ? 'Owner: ${team.ownerName}' : 'Owner: N/A',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  onPressed: () async {
                                    final confirm = await AppConfirmDialog.show(
                                     context,
                                     title: 'Delete Team',
                                     content: 'Delete team "${team.name}"? Players assigned to this team will remain in the database.',
                                     confirmText: 'Delete Team',
                                     isDestructive: true,
                                    );
                                    if (confirm == true) {
                                     await ref.read(teamRepositoryProvider).delete(team.id);
                                     if (context.mounted) {
                                       AppToast.showSuccess(context, 'Team "${team.name}" deleted.');
                                     }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Remaining: ${CurrencyFormatter.formatShort(team.purseRemaining)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Purse: ${CurrencyFormatter.formatShort(team.purseTotal)}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppColors.surfaceLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percent > 0.3 ? AppColors.success : AppColors.error,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Players: ${team.squadCount}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                Text(
                                  'Spent: ${CurrencyFormatter.formatShort(team.purseSpent)}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
          loading: () => LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 580 ? 2 : 1);
              final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(
                  crossAxisCount * 2,
                  (_) => SizedBox(
                    width: itemWidth,
                    child: const AppSkeleton.card(height: 180),
                  ),
                ),
              );
            },
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Teams',
            description: e.toString(),
            action: ElevatedButton.icon(
              onPressed: () => ref.invalidate(currentAuctionTeamsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ),
      ],
    );
  }
}
