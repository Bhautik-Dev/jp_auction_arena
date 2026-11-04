import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => InMemoryTeamRepository(
    tournamentRepository: ref.watch(tournamentRepositoryProvider),
    initialTeams: demoTeams,
  ),
);

final teamsProvider = FutureProvider<List<Team>>(
  (ref) => ref.watch(teamRepositoryProvider).getTeams(),
);
