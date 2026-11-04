import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class InMemoryPlayerRepository implements PlayerRepository {
  InMemoryPlayerRepository({
    required TeamRepository teamRepository,
    this.simulatedDelay = const Duration(milliseconds: 100),
    List<Player>? initialPlayers,
  }) : _teamRepository = teamRepository,
       _players = List.of(initialPlayers ?? const []);

  final TeamRepository _teamRepository;
  final Duration simulatedDelay;
  final List<Player> _players;
  int _nextId = 1;

  @override
  Future<List<Player>> getPlayers({
    String? query,
    PlayerCategory? category,
    PlayerStatus? status,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return List.unmodifiable(
      _players.where((player) {
        final matchesCategory = category == null || player.category == category;
        final matchesStatus = status == null || player.status == status;
        return matchesCategory &&
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
  Future<Player> createPlayer(Player player) async {
    await _wait();
    await _validate(player);
    final created = player.copyWith(
      id: player.id.isEmpty ? 'player_${_nextId++}' : player.id,
    );
    _players.add(created);
    return created;
  }

  @override
  Future<Player> updatePlayer(Player player) async {
    await _wait();
    final index = _players.indexWhere((item) => item.id == player.id);
    if (index < 0) {
      throw PlayerValidationException('Player ${player.id} not found.');
    }
    await _validate(player, excludingId: player.id);
    _players[index] = player;
    return player;
  }

  @override
  Future<bool> deletePlayer(String id) async {
    await _wait();
    final index = _players.indexWhere((player) => player.id == id);
    if (index < 0) return false;
    _players.removeAt(index);
    return true;
  }

  Future<void> _validate(Player player, {String? excludingId}) async {
    if (player.name.trim().isEmpty) {
      throw const PlayerValidationException('Player name is required.');
    }
    if (player.basePrice <= 0) {
      throw const PlayerValidationException(
        'Base price must be greater than zero.',
      );
    }
    final assignedTeamId = player.assignedTeamId;
    if (assignedTeamId != null &&
        await _teamRepository.getTeamById(assignedTeamId) == null) {
      throw PlayerValidationException(
        'Assigned team $assignedTeamId does not exist.',
      );
    }
    if (_players.any(
      (item) =>
          item.id != excludingId &&
          item.name.trim().toLowerCase() == player.name.trim().toLowerCase(),
    )) {
      throw const PlayerValidationException('Player name is already in use.');
    }
  }

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
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
