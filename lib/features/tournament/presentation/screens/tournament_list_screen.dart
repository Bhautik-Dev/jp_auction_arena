import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/responsive/app_breakpoints.dart';
import 'package:jp_auction_arena/core/theme/theme_mode_provider.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_card.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_filter_bar.dart';

/// Screen displaying the list of cricket tournaments with filtering,
/// search, and quick admin status actions.
class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: AppColors.goldAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Tournaments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 4),
          if (!isCompact)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: FilledButton.icon(
                onPressed: () => context.push('/tournaments/create'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Tournament'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.actionPink,
                  foregroundColor: AppColors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tournaments/create'),
        backgroundColor: AppColors.actionPink,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Tournament',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Search & Filter Header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TournamentFilterBar(),
              ),

              // Content Area (Loading, Error, Empty, or Populated)
              Expanded(
                child: tournamentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load tournaments',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(tournamentListProvider.notifier).refresh();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (tournaments) {
                    if (tournaments.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(tournamentListProvider.notifier).refresh();
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 900
                              ? 3
                              : width > 580
                                  ? 2
                                  : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 175,
                            ),
                            itemCount: tournaments.length,
                            itemBuilder: (context, index) {
                              final tournament = tournaments[index];
                              return TournamentCard(
                                tournament: tournament,
                                onStatusChange: (newStatus) async {
                                  await ref
                                      .read(tournamentListProvider.notifier)
                                      .changeStatus(tournament.id, newStatus);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${tournament.name} status updated to ${newStatus.label}',
                                        ),
                                        backgroundColor: newStatus.color,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                onDelete: () => _confirmDelete(
                                  context,
                                  ref,
                                  tournament.id,
                                  tournament.name,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 56,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Tournaments Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'No tournaments match your current filter. Create a new tournament or clear filters to view all entries.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(tournamentStatusFilterProvider.notifier).setFilter(null);
                    ref.read(tournamentSearchQueryProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear Filters'),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/tournaments/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Tournament'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament?'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tournamentListProvider.notifier).deleteTournament(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "$name"'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
