import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.role,
    required this.tournaments,
    required this.teams,
    required this.registeredPlayerCount,
    required this.soldPlayerCount,
    required this.playerCountDescription,
    required this.auctionStatus,
    required this.teamRegistrationProgress,
    required this.playerRegistrationProgress,
    required this.auctionConfigurationStatus,
    required this.recentActivity,
    required this.notifications,
    this.isDemoData = true,
  });

  final AppRole role;
  final List<DashboardTournamentSummary> tournaments;
  final List<DashboardTeamSummary> teams;
  final int registeredPlayerCount;
  final int soldPlayerCount;
  final String playerCountDescription;
  final String auctionStatus;
  final String teamRegistrationProgress;
  final String playerRegistrationProgress;
  final String auctionConfigurationStatus;
  final List<DashboardActivity> recentActivity;
  final List<String> notifications;
  final bool isDemoData;

  DashboardTournamentSummary? get activeTournament {
    for (final tournament in tournaments) {
      if (tournament.status == TournamentStatus.active) return tournament;
    }
    return null;
  }

  int get completedTournamentCount => tournaments
      .where((tournament) => tournament.status == TournamentStatus.completed)
      .length;

  int get activeTournamentCount => tournaments
      .where((tournament) => tournament.status == TournamentStatus.active)
      .length;
}

class DashboardTournamentSummary {
  const DashboardTournamentSummary({
    required this.id,
    required this.name,
    required this.seasonYear,
    required this.status,
    required this.registeredTeamCount,
    required this.teamLimit,
  });

  final String id;
  final String name;
  final String seasonYear;
  final TournamentStatus status;
  final int registeredTeamCount;
  final int teamLimit;
}

class DashboardTeamSummary {
  const DashboardTeamSummary({
    required this.id,
    required this.name,
    required this.shortName,
    required this.primaryColorValue,
    required this.status,
    required this.registeredPlayerCount,
    required this.soldPlayerCount,
    this.illustrativePurse = 1000000,
  });

  final String id;
  final String name;
  final String shortName;
  final int primaryColorValue;
  final TeamStatus status;
  final int registeredPlayerCount;
  final int soldPlayerCount;

  /// Example-only purse amount; the team feature has no purse configuration.
  final int illustrativePurse;

  int get illustrativeRemainingPurse => illustrativePurse;
}

class DashboardActivity {
  const DashboardActivity({required this.title, required this.description});

  final String title;
  final String description;
}
