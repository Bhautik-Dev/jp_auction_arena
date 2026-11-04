import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

abstract interface class TournamentRepository {
  Future<List<Tournament>> getTournaments({
    TournamentStatus? status,
    String? query,
  });

  Future<Tournament?> getTournamentById(String id);

  Future<Tournament> createTournament(Tournament tournament);

  Future<Tournament> updateTournament(Tournament tournament);

  Future<Tournament> updateTournamentStatus(String id, TournamentStatus status);

  Future<bool> deleteTournament(String id);
}
