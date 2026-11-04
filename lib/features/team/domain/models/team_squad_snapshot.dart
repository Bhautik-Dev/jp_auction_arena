import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_purse_account.dart';

class TeamSquadSnapshot {
  const TeamSquadSnapshot({
    required this.auction,
    required this.team,
    required this.purse,
    required this.purchasedPlayers,
    required this.categoryCounts,
    required this.warnings,
    required this.lastUpdatedAt,
  });

  final Auction auction;
  final Team team;
  final TeamPurseAccount purse;
  final List<Player> purchasedPlayers;
  final Map<PlayerCategory, int> categoryCounts;
  final List<String> warnings;
  final DateTime lastUpdatedAt;

  int get squadSize => purchasedPlayers.length;
  int get remainingSquadSlots => auction.maxPlayersPerTeam - squadSize;
  bool get meetsMinimumSquad =>
      purchasedPlayers.length >= auction.minPlayersPerTeam;
}
