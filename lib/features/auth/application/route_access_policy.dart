import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/models/role_permissions.dart';

abstract final class RouteAccessPolicy {
  static const splash = RouteNames.splash;
  static const login = RouteNames.login;
  static const forgotPassword = RouteNames.forgotPassword;
  static const unauthorized = RouteNames.unauthorized;
  static const teamPortal = RouteNames.teamPortal;
  static const publicLive = '/live/demo-event';

  static String landingFor(AppRole role) => switch (role) {
    AppRole.superAdmin || AppRole.tournamentAdmin => RouteNames.dashboard,
    AppRole.teamManager => teamPortal,
    AppRole.publicViewer => publicLive,
  };

  static bool canAccessPath(AuthUser user, String path) {
    if (path == unauthorized) return true;

    if (path == teamPortal) {
      return RolePermissions.allows(
            user.role,
            AppPermission.viewAssignedTeam,
          ) &&
          user.teamIds.isNotEmpty;
    }

    if (path.startsWith('/live/')) {
      return RolePermissions.allows(user.role, AppPermission.viewPublicLive);
    }

    final permission = _permissionFor(path);
    if (permission == null || !RolePermissions.allows(user.role, permission)) {
      return false;
    }

    if (user.role == AppRole.tournamentAdmin && _isTournamentScoped(path)) {
      final tournamentId = _tournamentIdFrom(path);
      if (tournamentId != null) {
        return RolePermissions.canAccessTournament(
          user.role,
          user.tournamentIds,
          tournamentId,
        );
      }
      return user.tournamentIds.isNotEmpty;
    }

    return true;
  }

  static AppPermission? _permissionFor(String path) {
    if (_matches(path, RouteNames.dashboard)) {
      return AppPermission.viewDashboard;
    }
    if (_matches(path, RouteNames.tournaments)) {
      return AppPermission.manageTournaments;
    }
    if (_matches(path, RouteNames.teams)) {
      return AppPermission.manageTeams;
    }
    if (_matches(path, RouteNames.players)) {
      return AppPermission.managePlayers;
    }
    if (_matches(path, RouteNames.auctionSetup)) {
      return AppPermission.configureAuction;
    }
    if (_matches(path, RouteNames.liveAuction)) {
      return AppPermission.operateAuction;
    }
    if (_matches(path, RouteNames.results)) {
      return AppPermission.viewResults;
    }
    if (_matches(path, RouteNames.reports)) {
      return AppPermission.viewReports;
    }
    if (_matches(path, RouteNames.history)) {
      return AppPermission.viewHistory;
    }
    if (_matches(path, RouteNames.settings)) {
      return AppPermission.manageSettings;
    }
    return null;
  }

  static bool _matches(String path, String route) =>
      path == route || path.startsWith('$route/');

  static bool _isTournamentScoped(String path) =>
      path.startsWith(RouteNames.tournaments) ||
      path.startsWith(RouteNames.teams) ||
      path.startsWith(RouteNames.players) ||
      path.startsWith('/app/auction/') ||
      path.startsWith(RouteNames.results) ||
      path.startsWith(RouteNames.reports) ||
      path.startsWith(RouteNames.history);

  static String? _tournamentIdFrom(String path) {
    final match = RegExp(r'^/app/tournaments/([^/]+)').firstMatch(path);
    return match?.group(1);
  }
}
