import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_status_badge.dart';

/// Detailed view of a single tournament with admin controls.
class TournamentDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(singleTournamentProvider(tournamentId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        actions: [
          IconButton(
            tooltip: 'Edit Tournament',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/tournaments/$tournamentId/edit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Failed to load tournament: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Tournaments'),
              ),
            ],
          ),
        ),
        data: (tournament) {
          if (tournament == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: AppColors.warning),
                  const SizedBox(height: 12),
                  const Text('Tournament not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Tournaments'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryNavy
                                        : AppColors.primaryDarkBlue.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tournament.shortName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.goldAccent
                                          : AppColors.primaryDarkBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Season ${tournament.seasonYear}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TournamentStatusBadge(status: tournament.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tournament.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: AppColors.lightBlueAccent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${tournament.venue}, ${tournament.city}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color?.withAlpha(210),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin Quick Actions Deck
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppColors.goldAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin Controls & Lifecycle',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                if (tournament.status.canActivate)
                                  FilledButton.icon(
                                    onPressed: () => _updateStatus(
                                      context,
                                      ref,
                                      tournament.id,
                                      TournamentStatus.active,
                                      'Tournament Activated! Ready for live auction operations.',
                                    ),
                                    icon: const Icon(Icons.play_arrow, size: 18),
                                    label: const Text('Activate Tournament'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                  ),
                                if (tournament.status.canDeactivate)
                                  OutlinedButton.icon(
                                    onPressed: () => _updateStatus(
                                      context,
                                      ref,
                                      tournament.id,
                                      TournamentStatus.draft,
                                      'Tournament moved back to Draft.',
                                    ),
                                    icon: const Icon(Icons.pause, size: 18),
                                    label: const Text('Deactivate to Draft'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.warning,
                                      side: const BorderSide(color: AppColors.warning),
                                    ),
                                  ),
                                if (tournament.status == TournamentStatus.active)
                                  FilledButton.icon(
                                    onPressed: () => _updateStatus(
                                      context,
                                      ref,
                                      tournament.id,
                                      TournamentStatus.completed,
                                      'Tournament marked as Completed.',
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Mark Completed'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlueAccent,
                                    ),
                                  ),
                                if (tournament.status.canArchive)
                                  OutlinedButton.icon(
                                    onPressed: () => _updateStatus(
                                      context,
                                      ref,
                                      tournament.id,
                                      TournamentStatus.archived,
                                      'Tournament Archived.',
                                    ),
                                    icon: const Icon(Icons.archive_outlined, size: 18),
                                    label: const Text('Archive Tournament'),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      context.push('/tournaments/${tournament.id}/edit'),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit Details'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Information Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dates & Schedule Card
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: AppColors.lightBlueAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tournament Dates',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      _buildInfoRow('Starts:', dateFormat.format(tournament.startDate)),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Ends:', dateFormat.format(tournament.endDate)),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Duration:', '${tournament.durationInDays} days'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isWide) const SizedBox(width: 16),
                            if (!isWide) const SizedBox(height: 16),

                            // Team Capacity Card
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.groups_outlined,
                                            size: 20,
                                            color: AppColors.goldAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Team & Squad Capacity',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      _buildInfoRow('Max Teams:', '${tournament.maxTeams} Teams allowed'),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('City:', tournament.city),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Venue:', tournament.venue),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Back Navigation Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to Tournament List'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    TournamentStatus status,
    String successMessage,
  ) async {
    await ref.read(tournamentListProvider.notifier).changeStatus(id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: status.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
