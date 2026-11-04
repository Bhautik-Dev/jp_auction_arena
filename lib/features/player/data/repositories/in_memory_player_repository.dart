import 'dart:async';

import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class InMemoryPlayerRepository implements PlayerRepository {
  InMemoryPlayerRepository({
    required TeamRepository teamRepository,
    this.auctionRepository,
    this.simulatedDelay = const Duration(milliseconds: 100),
    List<Player>? initialPlayers,
  }) : _teamRepository = teamRepository,
       _players = List.of(initialPlayers ?? const []);

  final TeamRepository _teamRepository;
  final AuctionRepository? auctionRepository;
  final Duration simulatedDelay;
  final List<Player> _players;
  Future<void> _writeTail = Future<void>.value();
  int _nextId = 1;

  @override
  Future<List<Player>> getPlayers({
    String? auctionId,
    String? query,
    PlayerCategory? category,
    PlayerStatus? status,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return List.unmodifiable(
      _players.where((player) {
        final matchesAuction =
            auctionId == null || player.auctionId == auctionId;
        final matchesCategory = category == null || player.category == category;
        final matchesStatus = status == null || player.status == status;
        return matchesAuction &&
            matchesCategory &&
            matchesStatus &&
            (normalizedQuery.isEmpty ||
                player.name.toLowerCase().contains(normalizedQuery));
      }),
    );
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    await _wait();
    for (final player in _players) {
      if (player.id == id) return player;
    }
    return null;
  }

  @override
  Future<Player> createPlayer(Player player) => _exclusive(() async {
    await _wait();
    await _validate(player);
    final created = player.copyWith(
      id: player.id.isEmpty ? _nextPlayerId() : player.id,
    );
    _players.add(created);
    return created;
  });

  @override
  Future<Player> updatePlayer(Player player) => _exclusive(() async {
    await _wait();
    final index = _players.indexWhere((item) => item.id == player.id);
    if (index < 0) {
      throw PlayerValidationException('Player ${player.id} not found.');
    }
    await _validate(player, excludingId: player.id);
    _players[index] = player;
    return player;
  });

  @override
  Future<List<Player>> importPlayers(List<Player> players) => _exclusive(
    () async {
      await _wait();
      final pending = <Player>[];
      for (final player in players) {
        await _validate(player, candidates: [..._players, ...pending]);
        pending.add(player);
      }
      final created = [
        for (final player in pending)
          player.copyWith(id: player.id.isEmpty ? _nextPlayerId() : player.id),
      ];
      _players.addAll(created);
      return List.unmodifiable(created);
    },
  );

  @override
  Future<bool> deletePlayer(String id) => _exclusive(() async {
    await _wait();
    final index = _players.indexWhere((player) => player.id == id);
    if (index < 0) return false;
    if (_players[index].status != PlayerStatus.available ||
        _players[index].assignedTeamId != null) {
      throw const PlayerDeletionBlockedException(
        'Players with an auction result or team assignment cannot be deleted.',
      );
    }
    _players.removeAt(index);
    return true;
  });

  Future<void> _validate(
    Player player, {
    String? excludingId,
    List<Player>? candidates,
  }) async {
    if (player.name.trim().isEmpty) {
      throw const PlayerValidationException('Player name is required.');
    }
    if (player.basePrice <= 0) {
      throw const PlayerValidationException(
        'Base price must be greater than zero.',
      );
    }
    if (player.age != null && (player.age! < 1 || player.age! > 100)) {
      throw const PlayerValidationException('Enter a valid player age.');
    }
    if (player.matchesPlayed < 0 ||
        player.runsScored < 0 ||
        player.wicketsTaken < 0) {
      throw const PlayerValidationException(
        'Player statistics cannot be negative.',
      );
    }
    if (player.purchasePrice != null &&
        (player.purchasePrice! <= 0 ||
            player.status != PlayerStatus.sold ||
            player.assignedTeamId == null)) {
      throw const PlayerValidationException(
        'Purchase price must be positive and linked to a sold player assignment.',
      );
    }
    if (player.auctionId.isNotEmpty) {
      final auctions = auctionRepository;
      if (auctions == null ||
          await auctions.getAuctionById(player.auctionId) == null) {
        throw PlayerValidationException(
          'Auction ${player.auctionId} was not found.',
        );
      }
    }
    final assignedTeamId = player.assignedTeamId;
    if (assignedTeamId != null) {
      final team = await _teamRepository.getTeamById(assignedTeamId);
      if (team == null ||
          (player.auctionId.isNotEmpty && team.auctionId != player.auctionId)) {
        throw PlayerValidationException(
          'Assigned team $assignedTeamId does not exist in this auction.',
        );
      }
    }
    final otherPlayers = candidates ?? _players;
    if (otherPlayers.any((item) {
      final sameScope = player.auctionId.isNotEmpty
          ? item.auctionId == player.auctionId
          : item.auctionId.isEmpty;
      return item.id != excludingId &&
          sameScope &&
          item.name.trim().toLowerCase() == player.name.trim().toLowerCase();
    })) {
      throw const PlayerValidationException('Player name is already in use.');
    }
  }

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
  }

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

  String _nextPlayerId() {
    while (true) {
      final id = 'player_${_nextId++}';
      if (_players.every((player) => player.id != id)) return id;
    }
  }
}

final demoPlayers = <Player>[
  Player(
    id: 'player_001',
    name: 'Aarav Patel',
    category: PlayerCategory.batsman,
    battingStyle: 'Right-hand bat',
    bowlingStyle: 'Right-arm medium',
    basePrice: 25000,
    contactNumber: '+91 98765 43210',
    status: PlayerStatus.available,
    assignedTeamId: null,
    createdAt: DateTime(2026, 1, 10),
    updatedAt: DateTime(2026, 1, 10),
    age: 24,
    matchesPlayed: 32,
    runsScored: 876,
  ),
  Player(
    id: 'player_002',
    name: 'Kabir Desai',
    category: PlayerCategory.bowler,
    battingStyle: 'Left-hand bat',
    bowlingStyle: 'Left-arm spin',
    basePrice: 20000,
    contactNumber: '+91 98765 23456',
    status: PlayerStatus.available,
    assignedTeamId: null,
    createdAt: DateTime(2026, 1, 11),
    updatedAt: DateTime(2026, 1, 11),
    age: 26,
    matchesPlayed: 28,
    wicketsTaken: 35,
  ),
];
