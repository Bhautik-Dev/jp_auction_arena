import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';

class PlayerFilterBar extends ConsumerStatefulWidget {
  const PlayerFilterBar({super.key});

  @override
  ConsumerState<PlayerFilterBar> createState() => _PlayerFilterBarState();
}

class _PlayerFilterBarState extends ConsumerState<PlayerFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(playerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(playerCategoryFilterProvider);
    final status = ref.watch(playerStatusFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search players by name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      ref.read(playerSearchQueryProvider.notifier).clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (value) {
            ref.read(playerSearchQueryProvider.notifier).setQuery(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final categoryDropdown = DropdownButtonFormField<PlayerCategory?>(
              initialValue: category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.sports_cricket_outlined),
              ),
              items: [
                const DropdownMenuItem<PlayerCategory?>(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final value in PlayerCategory.values)
                  DropdownMenuItem<PlayerCategory?>(
                    value: value,
                    child: Text(value.label),
                  ),
              ],
              onChanged: (value) => ref
                  .read(playerCategoryFilterProvider.notifier)
                  .setCategory(value),
            );
            final statusDropdown = DropdownButtonFormField<PlayerStatus?>(
              initialValue: status,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem<PlayerStatus?>(
                  value: null,
                  child: Text('All statuses'),
                ),
                for (final value in PlayerStatus.values)
                  DropdownMenuItem<PlayerStatus?>(
                    value: value,
                    child: Text(value.label),
                  ),
              ],
              onChanged: (value) => ref
                  .read(playerStatusFilterProvider.notifier)
                  .setStatus(value),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  categoryDropdown,
                  const SizedBox(height: 12),
                  statusDropdown,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 12),
                Expanded(child: statusDropdown),
              ],
            );
          },
        ),
      ],
    );
  }
}
