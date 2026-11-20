import 'package:flutter/material.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/utils/currency_formatter.dart';
import 'package:jp_auction_arena/core/theme/app_theme.dart';
import 'package:jp_auction_arena/core/widgets/glass_card.dart';
import 'package:jp_auction_arena/core/widgets/gradient_button.dart';
import 'package:jp_auction_arena/data/models/models.dart';
import 'package:jp_auction_arena/features/players/player_registration_form.dart';
import 'package:jp_auction_arena/shared/widgets/app_ui_feedback.dart';

/// Shows a detailed profile dialog for a player with Edit and Delete actions.
class PlayerProfileDialog extends StatelessWidget {
  final Player player;

  const PlayerProfileDialog({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        backgroundColor: AppColors.card,
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.2),
                    AppColors.secondaryPurple.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.cardRadius),
                  topRight: Radius.circular(AppTheme.cardRadius),
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'player_photo_${player.id}',
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: player.photoBase64 != null
                          ? NetworkImage(player.photoBase64!)
                          : null,
                      child: player.photoBase64 == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              size: 32,
                              color: AppColors.textMuted,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (player.isIcon) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ICON',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Player ID: #${player.playerNo}  •  ${player.id}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Row 1: Age | Jersey
                  Row(
                    children: [
                      _StatItem(label: 'Age', value: '${player.age} yrs'),
                      const SizedBox(width: 24),
                      _StatItem(label: 'Jersey #', value: '${player.playerNo}'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Role | Batting | Bowling
                  Row(
                    children: [
                      _StatItem(label: 'Role', value: player.category),
                      const SizedBox(width: 24),
                      _StatItem(label: 'Batting', value: player.battingStyle),
                      const SizedBox(width: 24),
                      _StatItem(label: 'Bowling', value: player.bowlingStyle),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 3: Village | Base Price
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'City / Village',
                          value: player.village.isNotEmpty ? player.village : 'Not specified',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _StatItem(
                          label: 'Base Price',
                          value: formatShort(player.basePrice),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 4: Mobile | Status
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'Mobile',
                          value: player.mobile ?? 'Not provided',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(player.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _statusColor(player.status).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                player.status.displayName.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(player.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // CricHeroes URL if present
                  if (player.cricHeroesUrl != null && player.cricHeroesUrl!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CricHeroes Profile',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  player.cricHeroesUrl!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Stats section if any
                  if (player.matches > 0 || player.runs > 0 || player.wickets > 0 || player.battingAverage > 0 || player.strikeRate > 0 || player.economy > 0) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatItem(label: 'Matches', value: '${player.matches}'),
                        const SizedBox(width: 24),
                        _StatItem(label: 'Runs', value: '${player.runs}'),
                        const SizedBox(width: 24),
                        _StatItem(label: 'Wickets', value: '${player.wickets}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatItem(label: 'Bat Avg', value: player.battingAverage.toStringAsFixed(2)),
                        const SizedBox(width: 24),
                        _StatItem(label: 'Strike Rate', value: player.strikeRate.toStringAsFixed(2)),
                        const SizedBox(width: 24),
                        _StatItem(label: 'Economy', value: player.economy.toStringAsFixed(2)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 26),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (_) => PlayerRegistrationForm(
                                playerToEdit: player,
                                onSaved: () {},
                              ),
                            );
                          },
                          icon: Icons.edit_rounded,
                          label: 'Edit Player',
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: () async {
                            final confirm = await AppConfirmDialog.show(
                              context,
                              title: 'Delete Player',
                              content:
                                  'Are you sure you want to remove "${player.name}" (#${player.playerNo})?',
                              confirmText: 'Delete',
                              isDestructive: true,
                            );
                            if (confirm == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          width: double.infinity,
                          gradient: const LinearGradient(
                            colors: [AppColors.error, AppColors.error],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.available:
        return AppColors.primaryBlue;
      case PlayerStatus.sold:
        return AppColors.success;
      case PlayerStatus.unsold:
        return AppColors.textMuted;
      case PlayerStatus.live:
        return AppColors.error;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
