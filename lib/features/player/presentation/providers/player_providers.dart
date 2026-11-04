import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/player/data/repositories/in_memory_player_repository.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/presentation/providers/team_providers.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return InMemoryPlayerRepository(
    teamRepository: ref.watch(teamRepositoryProvider),
    initialPlayers: demoPlayers,
  );
});

final playerSearchQueryProvider =
    NotifierProvider<PlayerSearchQueryNotifier, String>(
      PlayerSearchQueryNotifier.new,
    );

class PlayerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}

final playerCategoryFilterProvider =
    NotifierProvider<PlayerCategoryFilterNotifier, PlayerCategory?>(
      PlayerCategoryFilterNotifier.new,
    );

class PlayerCategoryFilterNotifier extends Notifier<PlayerCategory?> {
  @override
  PlayerCategory? build() => null;

  void setCategory(PlayerCategory? category) => state = category;
}

final playerStatusFilterProvider =
    NotifierProvider<PlayerStatusFilterNotifier, PlayerStatus?>(
      PlayerStatusFilterNotifier.new,
    );

class PlayerStatusFilterNotifier extends Notifier<PlayerStatus?> {
  @override
  PlayerStatus? build() => null;

  void setStatus(PlayerStatus? status) => state = status;
}

class PlayerListNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() {
    return ref
        .watch(playerRepositoryProvider)
        .getPlayers(
          query: ref.watch(playerSearchQueryProvider),
          category: ref.watch(playerCategoryFilterProvider),
          status: ref.watch(playerStatusFilterProvider),
        );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(playerRepositoryProvider)
          .getPlayers(
            query: ref.read(playerSearchQueryProvider),
            category: ref.read(playerCategoryFilterProvider),
            status: ref.read(playerStatusFilterProvider),
          ),
    );
  }

  Future<Player> createPlayer(Player player) async {
    final created = await ref
        .read(playerRepositoryProvider)
        .createPlayer(player);
    await refresh();
    return created;
  }

  Future<Player> updatePlayer(Player player) async {
    final updated = await ref
        .read(playerRepositoryProvider)
        .updatePlayer(player);
    await refresh();
    return updated;
  }

  Future<bool> deletePlayer(String id) async {
    final deleted = await ref.read(playerRepositoryProvider).deletePlayer(id);
    if (deleted) await refresh();
    return deleted;
  }
}

final playerListProvider =
    AsyncNotifierProvider<PlayerListNotifier, List<Player>>(
      PlayerListNotifier.new,
    );

final singlePlayerProvider = FutureProvider.family<Player?, String>((ref, id) {
  ref.watch(playerListProvider);
  return ref.read(playerRepositoryProvider).getPlayerById(id);
});

final teamsForPlayerAssignmentProvider = FutureProvider<List<Team>>((ref) {
  return ref.read(teamRepositoryProvider).getTeams();
});

final demoPlayers = [
  Player(
    id: 'player_001',
    name: 'Aarav Patel',
    category: PlayerCategory.batsman,
    battingStyle: 'Right-hand bat',
    bowlingStyle: 'Right-arm off break',
    basePrice: 50000,
    contactNumber: '+91 98765 11001',
    status: PlayerStatus.available,
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 2, 1),
  ),
  Player(
    id: 'player_002',
    name: 'Kabir Desai',
    category: PlayerCategory.bowler,
    battingStyle: 'Left-hand bat',
    bowlingStyle: 'Left-arm fast',
    basePrice: 35000,
    contactNumber: '+91 98765 11002',
    status: PlayerStatus.available,
    createdAt: DateTime(2026, 2, 2),
    updatedAt: DateTime(2026, 2, 2),
  ),
  Player(
    id: 'player_003',
    name: 'Vivaan Shah',
    category: PlayerCategory.allRounder,
    battingStyle: 'Right-hand bat',
    bowlingStyle: 'Right-arm medium',
    basePrice: 75000,
    status: PlayerStatus.sold,
    assignedTeamId: 'team_001',
    createdAt: DateTime(2026, 2, 3),
    updatedAt: DateTime(2026, 2, 3),
  ),
  Player(
    id: 'player_004',
    name: 'Ishaan Mehta',
    category: PlayerCategory.wicketkeeper,
    battingStyle: 'Right-hand bat',
    bowlingStyle: '',
    basePrice: 40000,
    status: PlayerStatus.unsold,
    createdAt: DateTime(2026, 2, 4),
    updatedAt: DateTime(2026, 2, 4),
  ),
];
