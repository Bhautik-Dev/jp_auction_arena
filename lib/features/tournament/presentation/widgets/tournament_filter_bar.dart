import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

/// Search and status filter bar for the tournament list.
class TournamentFilterBar extends ConsumerStatefulWidget {
  const TournamentFilterBar({super.key});

  @override
  ConsumerState<TournamentFilterBar> createState() => _TournamentFilterBarState();
}

class _TournamentFilterBarState extends ConsumerState<TournamentFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(tournamentSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = ref.watch(tournamentStatusFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by tournament, venue, or city...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(tournamentSearchQueryProvider.notifier).clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceContainer
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlueAccent,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) {
            ref.read(tournamentSearchQueryProvider.notifier).setQuery(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: selectedStatus == null,
                onSelected: () {
                  ref
                      .read(tournamentStatusFilterProvider.notifier)
                      .setFilter(null);
                },
              ),
              const SizedBox(width: 8),
              ...TournamentStatus.values.map((status) {
                final isSelected = selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _FilterChip(
                    label: status.label,
                    icon: status.icon,
                    iconColor: status.color,
                    isSelected: isSelected,
                    onSelected: () {
                      ref
                          .read(tournamentStatusFilterProvider.notifier)
                          .setFilter(isSelected ? null : status);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Text(label),
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (iconColor ?? AppColors.primaryBlueAccent),
            )
          : null,
      selectedColor: AppColors.primaryBlueAccent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
