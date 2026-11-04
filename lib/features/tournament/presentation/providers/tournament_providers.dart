import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/services/tournament_management_service.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => InMemoryTournamentRepository(),
);

final tournamentsProvider = FutureProvider<List<Tournament>>(
  (ref) => ref.watch(tournamentRepositoryProvider).getTournaments(),
);

final tournamentManagementServiceProvider =
    Provider<TournamentManagementService>(
      (ref) => TournamentManagementService(
        repository: ref.watch(tournamentRepositoryProvider),
      ),
    );

final tournamentByIdProvider = FutureProvider.family<Tournament?, String>(
  (ref, id) => ref.watch(tournamentRepositoryProvider).getTournamentById(id),
);

final tournamentHistoryProvider = FutureProvider<List<Tournament>>((ref) async {
  final tournaments = await ref
      .watch(tournamentRepositoryProvider)
      .getTournaments();
  return tournaments
      .where(
        (item) =>
            item.status == TournamentStatus.completed ||
            item.status == TournamentStatus.archived,
      )
      .toList();
});
