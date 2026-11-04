import 'dart:async';

import 'package:jp_auction_arena/features/team/domain/models/purse_adjustment.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_purse_repository.dart';

class InMemoryTeamPurseRepository implements TeamPurseRepository {
  final Map<String, int> _initialAmounts = {};
  final Map<String, List<PurseAdjustment>> _adjustments = {};
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<int> getInitialPurse({
    required String auctionId,
    required String teamId,
    required int defaultAmount,
  }) async {
    final key = _key(auctionId, teamId);
    return _initialAmounts.putIfAbsent(key, () => defaultAmount);
  }

  @override
  Future<List<PurseAdjustment>> getAdjustments({
    required String auctionId,
    required String teamId,
  }) async =>
      List.unmodifiable(_adjustments[_key(auctionId, teamId)] ?? const []);

  @override
  Future<PurseAdjustment> addAdjustment(
    PurseAdjustment adjustment, {
    required int minimumEffectiveInitialPurse,
  }) => _exclusive(() async {
    final key = _key(adjustment.auctionId, adjustment.teamId);
    final currentAdjustments = _adjustments[key] ?? const [];
    final adjustedInitial =
        (_initialAmounts[key] ?? 0) +
        currentAdjustments.fold<int>(0, (total, entry) => total + entry.amount);
    if (adjustedInitial + adjustment.amount < minimumEffectiveInitialPurse) {
      throw const TeamValidationException(
        'The adjustment cannot reduce the initial purse below the amount spent.',
      );
    }
    (_adjustments[key] ??= <PurseAdjustment>[]).add(adjustment);
    return adjustment;
  });

  String _key(String auctionId, String teamId) => '$auctionId::$teamId';

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
