import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/auction/data/repositories/in_memory_auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_management_service.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';

final auctionRepositoryProvider = Provider<AuctionRepository>(
  (ref) => InMemoryAuctionRepository(),
);

final auctionManagementServiceProvider = Provider<AuctionManagementService>(
  (ref) => AuctionManagementService(
    repository: ref.watch(auctionRepositoryProvider),
  ),
);

final auctionsProvider = FutureProvider<List<Auction>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) throw StateError('Auction list requires a session.');
  return ref.watch(auctionManagementServiceProvider).list(session.user);
});

final auctionByIdProvider = FutureProvider.family<Auction, String>((
  ref,
  id,
) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) throw StateError('Auction details require a session.');
  return ref.watch(auctionManagementServiceProvider).getById(session.user, id);
});

final auctionHistoryProvider = FutureProvider<List<Auction>>((ref) async {
  final auctions = await ref.watch(auctionsProvider.future);
  return auctions
      .where(
        (auction) =>
            auction.status == AuctionStatus.completed ||
            auction.status == AuctionStatus.archived,
      )
      .toList();
});
