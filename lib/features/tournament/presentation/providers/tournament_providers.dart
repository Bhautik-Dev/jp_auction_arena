import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/tournament/data/repositories/in_memory_tournament_repository.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => InMemoryTournamentRepository(),
);

final tournamentsProvider = FutureProvider<List<Tournament>>(
  (ref) => ref.watch(tournamentRepositoryProvider).getTournaments(),
);
