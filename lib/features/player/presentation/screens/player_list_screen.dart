import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({super.key});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: _buildContent(context)));

  Widget _buildContent(BuildContext context) {
    final players = ref.watch(playersProvider(_query));
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Players',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: () =>
                  context.push('${GoRouterState.of(context).uri.path}/create'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Player'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search players',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        players.when(
          loading: () =>
              const SizedBox(height: 240, child: AppLoadingIndicator()),
          error: (error, stackTrace) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(playersProvider(_query)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox(
                height: 240,
                child: AppEmptyState(title: 'No players found'),
              );
            }
            return Column(
              children: [
                for (final player in items) ...[
                  AppCard(
                    onTap: () => context.push(
                      '${GoRouterState.of(context).uri.path}/${player.id}',
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(player.name.characters.first)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                player.category.label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Chip(label: Text(player.status.label)),
                      ],
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
