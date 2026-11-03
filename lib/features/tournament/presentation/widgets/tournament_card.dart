import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_status_badge.dart';

/// Responsive tournament card displaying details and admin control actions.
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final ValueChanged<TournamentStatus>? onStatusChange;
  final VoidCallback? onDelete;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onStatusChange,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tournaments/${tournament.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Short name, Status Badge & Admin Action Menu
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryNavy
                            : AppColors.primaryDarkBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tournament.shortName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDark ? AppColors.goldAccent : AppColors.primaryDarkBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TournamentStatusBadge(status: tournament.status, isCompact: true),
                  _buildActionsMenu(context),
                ],
              ),
              const SizedBox(height: 8),

              // Tournament Title
              Text(
                tournament.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Venue & City
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.lightBlueAccent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${tournament.venue}, ${tournament.city}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(200),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Schedule Dates & Teams Count
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(tournament.startDate)} – ${dateFormat.format(tournament.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.groups_outlined,
                    size: 14,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${tournament.maxTeams}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      tooltip: 'Tournament options',
      padding: EdgeInsets.zero,
      iconSize: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            context.push('/tournaments/${tournament.id}');
            break;
          case 'edit':
            context.push('/tournaments/${tournament.id}/edit');
            break;
          case 'activate':
            onStatusChange?.call(TournamentStatus.active);
            break;
          case 'deactivate':
            onStatusChange?.call(TournamentStatus.draft);
            break;
          case 'complete':
            onStatusChange?.call(TournamentStatus.completed);
            break;
          case 'archive':
            onStatusChange?.call(TournamentStatus.archived);
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 10),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Edit Tournament'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (tournament.status.canActivate)
          PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, size: 18, color: AppColors.success),
                const SizedBox(width: 10),
                const Text('Activate', style: TextStyle(color: AppColors.success)),
              ],
            ),
          ),
        if (tournament.status.canDeactivate)
          PopupMenuItem(
            value: 'deactivate',
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline, size: 18, color: AppColors.warning),
                const SizedBox(width: 10),
                const Text('Set to Draft', style: TextStyle(color: AppColors.warning)),
              ],
            ),
          ),
        if (tournament.status == TournamentStatus.active)
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: AppColors.primaryBlueAccent),
                const SizedBox(width: 10),
                const Text('Mark Completed', style: TextStyle(color: AppColors.primaryBlueAccent)),
              ],
            ),
          ),
        if (tournament.status.canArchive)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18),
                SizedBox(width: 10),
                Text('Archive'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
