import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import 'auction_repository.dart';
import 'bid_repository.dart';
import 'player_repository.dart';
import 'settings_repository.dart';
import 'team_repository.dart';
import 'sync/supabase_auction_repository.dart';
import 'sync/supabase_bid_repository.dart';
import 'sync/supabase_player_repository.dart';
import 'sync/supabase_team_repository.dart';

/// Holds references to all repository implementations currently in use.
class RepositoryBundle {
  const RepositoryBundle({
    required this.auction,
    required this.player,
    required this.team,
    required this.bid,
    required this.settings,
  });

  final AuctionRepository auction;
  final PlayerRepository player;
  final TeamRepository team;
  final BidRepository bid;
  final SettingsRepository settings;
}

/// Factory that selects the active repository implementation.
///
/// Supabase-backed repositories are used as the primary source of truth when
/// the Supabase client is initialized. Hive implementations are used only as
/// fallback when Supabase is unavailable (offline mode).
///
/// Hive is retained exclusively for [SettingsRepository] (UI preferences) and
/// as an optional offline cache.
class RepositoryFactory {
  const RepositoryFactory._();

  /// Select the correct [AuctionRepository] implementation.
  static AuctionRepository auction() {
    final client = SupabaseClientService.instance.client;
    if (client != null) {
      return SupabaseAuctionRepository(client);
    }
    return HiveAuctionRepository();
  }

  /// Select the correct [PlayerRepository] implementation.
  static PlayerRepository player() {
    final client = SupabaseClientService.instance.client;
    if (client != null) {
      return SupabasePlayerRepository(client);
    }
    return HivePlayerRepository();
  }

  /// Select the correct [TeamRepository] implementation.
  static TeamRepository team() {
    final client = SupabaseClientService.instance.client;
    if (client != null) {
      return SupabaseTeamRepository(client);
    }
    return HiveTeamRepository();
  }

  /// Select the correct [BidRepository] implementation.
  static BidRepository bid() {
    final client = SupabaseClientService.instance.client;
    if (client != null) {
      return SupabaseBidRepository(client);
    }
    return HiveBidRepository();
  }

  /// Settings always use Hive (UI preferences, offline cache only).
  static SettingsRepository settings() => HiveSettingsRepository();

  /// Build a [RepositoryBundle] containing all five repositories.
  static RepositoryBundle bundle() => RepositoryBundle(
        auction: auction(),
        player: player(),
        team: team(),
        bid: bid(),
        settings: settings(),
      );
}

/// Riverpod provider exposing the full [RepositoryBundle].
///
/// Repositories are selected once at app startup and remain stable for the
/// lifetime of the app. If Supabase becomes configured later, the app must be
/// restarted for the new implementation to take effect.
final repositoryFactoryProvider = Provider<RepositoryBundle>((ref) {
  return RepositoryFactory.bundle();
});
