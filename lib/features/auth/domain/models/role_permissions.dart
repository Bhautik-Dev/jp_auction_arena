import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';

abstract final class RolePermissions {
  static const _all = AppPermission.values;

  static const _tournamentAdmin = {
    AppPermission.viewDashboard,
    AppPermission.manageTournaments,
    AppPermission.viewTournament,
    AppPermission.manageTeams,
    AppPermission.managePlayers,
    AppPermission.viewPlayers,
    AppPermission.configureAuction,
    AppPermission.operateAuction,
    AppPermission.viewAuction,
    AppPermission.viewResults,
    AppPermission.viewReports,
    AppPermission.viewHistory,
    AppPermission.viewPublicLive,
  };

  static const _teamManager = {
    AppPermission.viewDashboard,
    AppPermission.viewAssignedTeam,
    AppPermission.viewPlayers,
    AppPermission.viewAuction,
    AppPermission.viewResults,
    AppPermission.viewPublicLive,
  };

  static const _publicViewer = {
    AppPermission.viewDashboard,
    AppPermission.viewPublicLive,
    AppPermission.viewResults,
  };

  static Set<AppPermission> forRole(AppRole role) => switch (role) {
    AppRole.superAdmin => _all.toSet(),
    AppRole.tournamentAdmin => _tournamentAdmin,
    AppRole.teamManager => _teamManager,
    AppRole.publicViewer => _publicViewer,
  };

  static bool allows(AppRole role, AppPermission permission) =>
      forRole(role).contains(permission);

  static bool canAccessTournament(
    AppRole role,
    Set<String> assignedIds,
    String tournamentId,
  ) => role == AppRole.superAdmin || assignedIds.contains(tournamentId);

  static bool canAccessTeam(
    AppRole role,
    Set<String> assignedIds,
    String teamId,
  ) => role == AppRole.superAdmin || assignedIds.contains(teamId);
}
