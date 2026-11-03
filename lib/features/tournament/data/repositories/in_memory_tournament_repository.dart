import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

/// In-memory implementation of [TournamentRepository].
/// Pre-seeded with sample cricket tournaments and ready to be replaced
/// with a PostgreSQL/Supabase repository in future phases.
class InMemoryTournamentRepository implements TournamentRepository {
  final List<Tournament> _tournaments = [];
  final Duration simulatedDelay;

  InMemoryTournamentRepository({
    this.simulatedDelay = const Duration(milliseconds: 200),
  }) {
    _seedInitialTournaments();
  }

  void _seedInitialTournaments() {
    final now = DateTime.now();

    _tournaments.addAll([
      Tournament(
        id: 'tourn_001',
        name: 'Gujarat Premier Auction Arena 2026',
        shortName: 'GPAA 2026',
        seasonYear: '2026',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 25)),
        city: 'Ahmedabad',
        venue: 'Narendra Modi Stadium',
        maxTeams: 8,
        status: TournamentStatus.active,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Tournament(
        id: 'tourn_002',
        name: 'Surat Corporate Super League',
        shortName: 'SCSL 2026',
        seasonYear: '2026',
        startDate: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 42)),
        city: 'Surat',
        venue: 'Lalbhai Contractor Stadium',
        maxTeams: 10,
        status: TournamentStatus.draft,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Tournament(
        id: 'tourn_003',
        name: 'Baroda Champions Trophy 2025',
        shortName: 'BCT 2025',
        seasonYear: '2025',
        startDate: now.subtract(const Duration(days: 120)),
        endDate: now.subtract(const Duration(days: 105)),
        city: 'Vadodara',
        venue: 'Reliance Cricket Stadium',
        maxTeams: 6,
        status: TournamentStatus.completed,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 100)),
      ),
      Tournament(
        id: 'tourn_004',
        name: 'Saurashtra Invitation Cup 2024',
        shortName: 'SIC 2024',
        seasonYear: '2024',
        startDate: now.subtract(const Duration(days: 400)),
        endDate: now.subtract(const Duration(days: 385)),
        city: 'Rajkot',
        venue: 'SCA Stadium, Khandheri',
        maxTeams: 8,
        status: TournamentStatus.archived,
        createdAt: now.subtract(const Duration(days: 450)),
        updatedAt: now.subtract(const Duration(days: 380)),
      ),
    ]);
  }

  @override
  Future<List<Tournament>> getTournaments({
    TournamentStatus? status,
    String? query,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    var result = List<Tournament>.from(_tournaments);

    if (status != null) {
      result = result.where((t) => t.status == status).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.shortName.toLowerCase().contains(q) ||
            t.city.toLowerCase().contains(q) ||
            t.venue.toLowerCase().contains(q) ||
            t.seasonYear.contains(q);
      }).toList();
    }

    // Sort: Active first, then Draft, then Completed, then Archived; then by startDate
    result.sort((a, b) {
      final priorityA = _statusSortPriority(a.status);
      final priorityB = _statusSortPriority(b.status);
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return result;
  }

  int _statusSortPriority(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.active:
        return 0;
      case TournamentStatus.draft:
        return 1;
      case TournamentStatus.completed:
        return 2;
      case TournamentStatus.archived:
        return 3;
    }
  }

  @override
  Future<Tournament?> getTournamentById(String id) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    try {
      return _tournaments.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Tournament> createTournament(Tournament tournament) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final newTournament = tournament.copyWith(
      id: tournament.id.isEmpty
          ? 'tourn_${DateTime.now().millisecondsSinceEpoch}'
          : tournament.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _tournaments.insert(0, newTournament);
    return newTournament;
  }

  @override
  Future<Tournament> updateTournament(Tournament tournament) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final index = _tournaments.indexWhere((t) => t.id == tournament.id);
    if (index == -1) {
      throw Exception('Tournament not found with id: ${tournament.id}');
    }

    final updated = tournament.copyWith(
      updatedAt: DateTime.now(),
    );

    _tournaments[index] = updated;
    return updated;
  }

  @override
  Future<Tournament> updateTournamentStatus(
    String id,
    TournamentStatus newStatus,
  ) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final index = _tournaments.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Tournament not found with id: $id');
    }

    final updated = _tournaments[index].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    _tournaments[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTournament(String id) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final initialCount = _tournaments.length;
    _tournaments.removeWhere((t) => t.id == id);
    return _tournaments.length < initialCount;
  }
}
