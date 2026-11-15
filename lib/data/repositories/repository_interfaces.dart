// Repository abstraction interfaces for JP AUCTION ARENA.
//
// These interfaces define the contract for data access. The Hive
// repositories and the Supabase-backed repositories in sync/ both implement
// these interfaces, allowing the UI layer to remain agnostic to the storage
// backend. The concrete implementation is selected at app startup by
// RepositoryFactory and injected via Riverpod.

export 'auction_repository.dart';
export 'player_repository.dart';
export 'team_repository.dart';
export 'bid_repository.dart';
export 'settings_repository.dart';