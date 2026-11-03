import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/team/data/repositories/in_memory_team_repository.dart';
import 'package:jp_auction_arena/features/team/data/services/team_logo_picker.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';
import 'package:jp_auction_arena/features/tournament/presentation/providers/tournament_providers.dart';

final teamLogoPickerProvider = Provider<TeamLogoPicker>(
  (ref) => const FilePickerTeamLogoPicker(),
);

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final tournamentRepository = ref.watch(tournamentRepositoryProvider);
  return InMemoryTeamRepository(
    tournamentRepository: tournamentRepository,
    initialTeams: demoTeams,
  );
});

final teamSearchQueryProvider =
    NotifierProvider<TeamSearchQueryNotifier, String>(
      TeamSearchQueryNotifier.new,
    );

class TeamSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}

final teamTournamentFilterProvider =
    NotifierProvider<TeamTournamentFilterNotifier, String?>(
      TeamTournamentFilterNotifier.new,
    );

class TeamTournamentFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTournament(String? tournamentId) => state = tournamentId;
}

final teamStatusFilterProvider =
    NotifierProvider<TeamStatusFilterNotifier, TeamStatus?>(
      TeamStatusFilterNotifier.new,
    );

class TeamStatusFilterNotifier extends Notifier<TeamStatus?> {
  @override
  TeamStatus? build() => null;

  void setStatus(TeamStatus? status) => state = status;
}

class TeamListNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() {
    final repository = ref.watch(teamRepositoryProvider);
    final tournamentId = ref.watch(teamTournamentFilterProvider);
    final status = ref.watch(teamStatusFilterProvider);
    final query = ref.watch(teamSearchQueryProvider);
    return repository.getTeams(
      tournamentId: tournamentId,
      status: status,
      query: query,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref
          .read(teamRepositoryProvider)
          .getTeams(
            tournamentId: ref.read(teamTournamentFilterProvider),
            status: ref.read(teamStatusFilterProvider),
            query: ref.read(teamSearchQueryProvider),
          );
    });
  }

  Future<Team> createTeam(Team team) async {
    final created = await ref.read(teamRepositoryProvider).createTeam(team);
    await refresh();
    return created;
  }

  Future<Team> updateTeam(Team team) async {
    final updated = await ref.read(teamRepositoryProvider).updateTeam(team);
    await refresh();
    return updated;
  }

  Future<Team> changeStatus(String id, TeamStatus status) async {
    final updated = await ref
        .read(teamRepositoryProvider)
        .updateTeamStatus(id, status);
    await refresh();
    return updated;
  }

  Future<bool> deleteTeam(String id) async {
    final deleted = await ref.read(teamRepositoryProvider).deleteTeam(id);
    if (deleted) await refresh();
    return deleted;
  }
}

final teamListProvider = AsyncNotifierProvider<TeamListNotifier, List<Team>>(
  TeamListNotifier.new,
);

final singleTeamProvider = FutureProvider.family<Team?, String>((ref, id) {
  ref.watch(teamListProvider);
  return ref.read(teamRepositoryProvider).getTeamById(id);
});

final demoTeams = [
  Team(
    id: 'team_001',
    tournamentId: 'tourn_001',
    name: 'Ahmedabad Strikers',
    shortName: 'AST',
    primaryColorValue: 0xFF2A63DD,
    secondaryColorValue: 0xFFFF4FA8,
    ownerName: 'Arjun Mehta',
    managerName: 'Karan Shah',
    contactEmail: 'strikers@example.com',
    contactPhone: '+91 98765 43210',
    status: TeamStatus.active,
    createdAt: DateTime(2026, 1, 10),
    updatedAt: DateTime(2026, 1, 10),
  ),
  Team(
    id: 'team_002',
    tournamentId: 'tourn_001',
    name: 'Sabarmati Royals',
    shortName: 'SROY',
    primaryColorValue: 0xFFD946EF,
    secondaryColorValue: 0xFF2A63DD,
    ownerName: 'Nisha Patel',
    managerName: 'Dev Trivedi',
    contactEmail: 'royals@example.com',
    contactPhone: '+91 98765 12345',
    status: TeamStatus.active,
    createdAt: DateTime(2026, 1, 12),
    updatedAt: DateTime(2026, 1, 12),
  ),
  Team(
    id: 'team_003',
    tournamentId: 'tourn_002',
    name: 'Surat Cyclones',
    shortName: 'SCY',
    primaryColorValue: 0xFFFF4FA8,
    secondaryColorValue: 0xFF211B3D,
    ownerName: 'Rohan Desai',
    managerName: 'Mihir Joshi',
    contactEmail: 'cyclones@example.com',
    contactPhone: '+91 98989 45678',
    status: TeamStatus.inactive,
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 2, 1),
  ),
];
