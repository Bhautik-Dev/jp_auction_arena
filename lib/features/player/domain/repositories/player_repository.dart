import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';

abstract interface class PlayerRepository {
  Future<List<Player>> getPlayers({
    String? auctionId,
    String? query,
    PlayerCategory? category,
    PlayerStatus? status,
  });

  Future<Player?> getPlayerById(String id);

  Future<Player> createPlayer(Player player);

  Future<Player> updatePlayer(Player player);

  Future<List<Player>> importPlayers(List<Player> players);

  Future<bool> deletePlayer(String id);
}
