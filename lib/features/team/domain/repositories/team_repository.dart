import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams({
    String? tournamentId,
    TeamStatus? status,
    String? query,
  });

  Future<Team?> getTeamById(String id);

  Future<Team> createTeam(Team team);

  Future<Team> updateTeam(Team team);

  Future<Team> updateTeamStatus(String id, TeamStatus status);

  Future<bool> deleteTeam(String id);
}
