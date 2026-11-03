import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

/// Repository interface defining data access contracts for Tournaments.
abstract class TournamentRepository {
  /// Fetches tournaments with optional status filtering and search query.
  Future<List<Tournament>> getTournaments({
    TournamentStatus? status,
    String? query,
  });

  /// Fetches a single tournament by its unique identifier.
  Future<Tournament?> getTournamentById(String id);

  /// Creates a new tournament.
  Future<Tournament> createTournament(Tournament tournament);

  /// Updates an existing tournament.
  Future<Tournament> updateTournament(Tournament tournament);

  /// Fast-tracks updating tournament status (Draft -> Active -> Completed -> Archived).
  Future<Tournament> updateTournamentStatus(
    String id,
    TournamentStatus newStatus,
  );

  /// Deletes a tournament by id.
  Future<bool> deleteTournament(String id);
}
