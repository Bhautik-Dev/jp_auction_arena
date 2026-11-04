import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:jp_auction_arena/features/tournament/presentation/widgets/tournament_widgets.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen> {
  final _searchController = TextEditingController();
  TournamentStatus? _status;
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(tournamentsProvider);
    final user = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    final canCreate =
        user != null &&
        (user.role == AppRole.superAdmin ||
            (user.role == AppRole.tournamentAdmin &&
                user.tournamentIds.isNotEmpty));

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tournaments',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => context.go(RouteNames.tournamentCreate),
                icon: const Icon(Icons.add),
                label: const Text('New Tournament'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Search tournaments',
            hintText: 'Search by tournament name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _filterChip('All', null),
            for (final status in TournamentStatus.values)
              _filterChip(status.label, status),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<bool>(
              value: _newestFirst,
              items: const [
                DropdownMenuItem(value: true, child: Text('Newest first')),
                DropdownMenuItem(value: false, child: Text('Oldest first')),
              ],
              onChanged: (value) =>
                  setState(() => _newestFirst = value ?? true),
            ),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _status = null;
                  _newestFirst = true;
                });
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        tournaments.when(
          loading: () =>
              const SizedBox(height: 240, child: AppLoadingIndicator()),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(tournamentsProvider),
          ),
          data: (items) =>
              _buildResults(items, user?.role, user?.tournamentIds),
        ),
      ],
    );
  }

  Widget _buildResults(
    List<Tournament> items,
    AppRole? role,
    Set<String>? assignedTournamentIds,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final visible =
        items.where((tournament) {
          final matchesAssignment =
              role != AppRole.tournamentAdmin ||
              (assignedTournamentIds?.contains(tournament.id) ?? false);
          final matchesStatus = _status == null || tournament.status == _status;
          final matchesName =
              query.isEmpty || tournament.name.toLowerCase().contains(query);
          return matchesAssignment && matchesStatus && matchesName;
        }).toList()..sort((left, right) {
          final result = left.startDate.compareTo(right.startDate);
          return _newestFirst ? -result : result;
        });

    if (visible.isEmpty) {
      return const SizedBox(
        height: 240,
        child: AppEmptyState(
          title: 'No tournaments found',
          message: 'Try adjusting your search or clearing the status filter.',
        ),
      );
    }

    return Column(
      children: [
        for (final tournament in visible) ...[
          TournamentListCard(
            tournament: tournament,
            onOpen: () =>
                context.go(RouteNames.tournamentDetailPath(tournament.id)),
            onEdit: tournament.status == TournamentStatus.archived
                ? null
                : () =>
                      context.go(RouteNames.tournamentEditPath(tournament.id)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _filterChip(String label, TournamentStatus? status) => FilterChip(
    label: Text(label),
    selected: _status == status,
    onSelected: (_) => setState(() => _status = status),
  );
}

class TournamentHistoryScreen extends ConsumerWidget {
  const TournamentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tournamentHistoryProvider);
    final user = ref
        .watch(authSessionProvider)
        .whenOrNull(data: (session) => session?.user);
    return ListView(
      children: [
        Text(
          'Tournament History / Archives',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Completed records are retained. Archived tournaments are read-only '
          'until an authorized administrator restores them.',
        ),
        const SizedBox(height: AppSpacing.lg),
        history.when(
          loading: () =>
              const SizedBox(height: 240, child: AppLoadingIndicator()),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(tournamentHistoryProvider),
          ),
          data: (items) {
            final scoped = items.where(
              (item) =>
                  user?.role != AppRole.tournamentAdmin ||
                  (user?.tournamentIds.contains(item.id) ?? false),
            );
            final sorted = scoped.toList()
              ..sort((a, b) => b.startDate.compareTo(a.startDate));
            if (sorted.isEmpty) {
              return const SizedBox(
                height: 240,
                child: AppEmptyState(
                  title: 'No tournament history',
                  message: 'Completed and archived tournaments appear here.',
                ),
              );
            }
            return Column(
              children: [
                for (final tournament in sorted) ...[
                  TournamentListCard(
                    tournament: tournament,
                    onOpen: () => context.go(
                      RouteNames.tournamentDetailPath(tournament.id),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
