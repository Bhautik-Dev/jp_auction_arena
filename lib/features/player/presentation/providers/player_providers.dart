import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => InMemoryPlayerRepository(
    teamRepository: ref.watch(teamRepositoryProvider),
    initialPlayers: demoPlayers,
  ),
);

final playersProvider = FutureProvider.family<List<Player>, String>((
  ref,
  query,
) {
  return ref.watch(playerRepositoryProvider).getPlayers(query: query);
});
