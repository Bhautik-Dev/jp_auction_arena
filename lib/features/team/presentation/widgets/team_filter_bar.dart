import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';

class TeamFilterBar extends ConsumerStatefulWidget {
  const TeamFilterBar({required this.tournaments, super.key});

  final List<Tournament> tournaments;

  @override
  ConsumerState<TeamFilterBar> createState() => _TeamFilterBarState();
}

class _TeamFilterBarState extends ConsumerState<TeamFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(teamSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = ref.watch(teamStatusFilterProvider);
    final selectedTournament = ref.watch(teamTournamentFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search teams, owners, managers, or contacts',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      ref.read(teamSearchQueryProvider.notifier).clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (value) {
            ref.read(teamSearchQueryProvider.notifier).setQuery(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: selectedTournament,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tournament',
            prefixIcon: Icon(Icons.emoji_events_outlined),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All tournaments'),
            ),
            for (final tournament in widget.tournaments)
              DropdownMenuItem<String?>(
                value: tournament.id,
                child: Text(
                  tournament.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            ref
                .read(teamTournamentFilterProvider.notifier)
                .setTournament(value);
          },
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusFilterChip(
                label: 'All statuses',
                selected: selectedStatus == null,
                onSelected: () =>
                    ref.read(teamStatusFilterProvider.notifier).setStatus(null),
              ),
              for (final status in TeamStatus.values)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _StatusFilterChip(
                    label: status.label,
                    color: status.color,
                    selected: selectedStatus == status,
                    onSelected: () => ref
                        .read(teamStatusFilterProvider.notifier)
                        .setStatus(selectedStatus == status ? null : status),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.softPurple,
      checkmarkColor: AppColors.neonPink,
      side: BorderSide(color: selected ? AppColors.neonPink : AppColors.muted),
      avatar: color == null ? null : Icon(Icons.circle, size: 12, color: color),
    );
  }
}
