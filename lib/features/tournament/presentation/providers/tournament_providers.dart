import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

/// Provider for the [TournamentRepository] singleton.
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return InMemoryTournamentRepository();
});

/// Notifier managing status filter (null for all tournaments).
class TournamentStatusFilterNotifier extends Notifier<TournamentStatus?> {
  @override
  TournamentStatus? build() => null;

  void setFilter(TournamentStatus? status) {
    state = status;
  }
}

final tournamentStatusFilterProvider =
    NotifierProvider<TournamentStatusFilterNotifier, TournamentStatus?>(() {
  return TournamentStatusFilterNotifier();
});

/// Notifier managing search query for filtering tournament names/locations.
class TournamentSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final tournamentSearchQueryProvider =
    NotifierProvider<TournamentSearchQueryNotifier, String>(() {
  return TournamentSearchQueryNotifier();
});

/// Main AsyncNotifier managing the reactive tournament list and mutations.
class TournamentListNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() async {
    final repository = ref.watch(tournamentRepositoryProvider);
    final status = ref.watch(tournamentStatusFilterProvider);
    final query = ref.watch(tournamentSearchQueryProvider);

    return repository.getTournaments(
      status: status,
      query: query,
    );
  }

  /// Refreshes tournament list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      final status = ref.read(tournamentStatusFilterProvider);
      final query = ref.read(tournamentSearchQueryProvider);
      return repository.getTournaments(status: status, query: query);
    });
  }

  /// Creates a new tournament and reloads list.
  Future<Tournament> createTournament(Tournament tournament) async {
    final repository = ref.read(tournamentRepositoryProvider);
    final created = await repository.createTournament(tournament);
    await refresh();
    return created;
  }

  /// Updates an existing tournament.
  Future<Tournament> updateTournament(Tournament tournament) async {
    final repository = ref.read(tournamentRepositoryProvider);
    final updated = await repository.updateTournament(tournament);
    await refresh();
    return updated;
  }

  /// Changes the status of a tournament (e.g., Draft -> Active or Completed -> Archived).
  Future<Tournament> changeStatus(
    String id,
    TournamentStatus newStatus,
  ) async {
    final repository = ref.read(tournamentRepositoryProvider);
    final updated = await repository.updateTournamentStatus(id, newStatus);
    await refresh();
    return updated;
  }

  /// Deletes a tournament by id.
  Future<bool> deleteTournament(String id) async {
    final repository = ref.read(tournamentRepositoryProvider);
    final success = await repository.deleteTournament(id);
    if (success) {
      await refresh();
    }
    return success;
  }
}

final tournamentListProvider =
    AsyncNotifierProvider<TournamentListNotifier, List<Tournament>>(() {
  return TournamentListNotifier();
});

/// Provider to get a single tournament by ID.
final singleTournamentProvider =
    FutureProvider.family<Tournament?, String>((ref, id) async {
  // Watch tournamentListProvider so if a tournament is updated/status changed,
  // singleTournamentProvider automatically refreshes!
  ref.watch(tournamentListProvider);
  final repository = ref.read(tournamentRepositoryProvider);
  return repository.getTournamentById(id);
});
