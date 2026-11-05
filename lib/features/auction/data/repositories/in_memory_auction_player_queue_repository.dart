import 'dart:async';

import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_player_queue.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_player_queue_repository.dart';

class InMemoryAuctionPlayerQueueRepository
    implements AuctionPlayerQueueRepository {
  final Map<String, AuctionPlayerQueue> _queues = {};
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<AuctionPlayerQueue> getQueue(String auctionId) async =>
      _queues[auctionId] ??
      AuctionPlayerQueue(
        auctionId: auctionId,
        playerIds: const [],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  Future<AuctionPlayerQueue> saveQueue(AuctionPlayerQueue queue) =>
      updateQueue(queue.auctionId, (_) => queue.playerIds, queue.updatedAt);

  @override
  Future<AuctionPlayerQueue> updateQueue(
    String auctionId,
    List<String> Function(List<String> currentPlayerIds) update,
    DateTime updatedAt,
  ) => _exclusive(() async {
    if (auctionId.trim().isEmpty) {
      throw const AuctionValidationException(
        'Auction queue must be scoped to an auction.',
      );
    }
    final playerIds = update(
      List.unmodifiable(_queues[auctionId]?.playerIds ?? const []),
    );
    if (playerIds.toSet().length != playerIds.length) {
      throw const AuctionValidationException(
        'Auction queue must contain unique players.',
      );
    }
    final saved = AuctionPlayerQueue(
      auctionId: auctionId,
      playerIds: List.unmodifiable(playerIds),
      updatedAt: updatedAt,
    );
    _queues[auctionId] = saved;
    return saved;
  });

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final previous = _writeTail;
    final finished = Completer<void>();
    _writeTail = finished.future;
    await previous;
    try {
      return await action();
    } finally {
      finished.complete();
    }
  }
}
