import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.role,
    required this.auctions,
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
  final List<DashboardAuctionSummary> auctions;
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

  DashboardAuctionSummary? get liveAuction {
    for (final auction in auctions) {
      if (auction.status == AuctionStatus.live) return auction;
    }
    return null;
  }

  int get draftAuctionCount =>
      auctions.where((auction) => auction.status == AuctionStatus.draft).length;

  int get upcomingAuctionCount =>
      auctions.where((auction) => auction.status == AuctionStatus.ready).length;

  int get liveAuctionCount =>
      auctions.where((auction) => auction.status == AuctionStatus.live).length;

  int get completedAuctionCount => auctions
      .where(
        (auction) =>
            auction.status == AuctionStatus.completed ||
            auction.status == AuctionStatus.archived,
      )
      .length;
}

class DashboardAuctionSummary {
  const DashboardAuctionSummary({
    required this.id,
    required this.name,
    required this.auctionDate,
    required this.startTimeMinutes,
    required this.status,
    required this.cricketFormat,
    required this.customFormat,
    required this.maxTeams,
    required this.maxPlayersPerTeam,
    required this.minPlayersPerTeam,
    required this.totalPursePerTeam,
    required this.baseCurrency,
  });

  final String id;
  final String name;
  final DateTime auctionDate;
  final int startTimeMinutes;
  final AuctionStatus status;
  final CricketFormat cricketFormat;
  final String? customFormat;
  final int maxTeams;
  final int maxPlayersPerTeam;
  final int minPlayersPerTeam;
  final double totalPursePerTeam;
  final String baseCurrency;
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
  final int illustrativePurse;

  int get illustrativeRemainingPurse => illustrativePurse;
}

class DashboardActivity {
  const DashboardActivity({required this.title, required this.description});

  final String title;
  final String description;
}
