import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/player/presentation/providers/player_providers.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({required this.playerId, super.key});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: FutureBuilder(
        future: ref.read(playerRepositoryProvider).getPlayerById(playerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorState(error: snapshot.error!);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator();
          }
          final player = snapshot.data;
          if (player == null) {
            return const AppEmptyState(title: 'Player not found');
          }
          return ListView(
            children: [
              Text(
                'Player details',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Category'),
                    Text(player.category.label),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Base price'),
                    Text(player.basePrice.toString()),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Status'),
                    Text(player.status.label),
                    Text('Batting style: ${player.battingStyle}'),
                    Text('Bowling style: ${player.bowlingStyle}'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
