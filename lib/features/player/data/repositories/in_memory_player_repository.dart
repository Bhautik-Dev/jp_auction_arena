import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class InMemoryPlayerRepository implements PlayerRepository {
  InMemoryPlayerRepository({
    required TeamRepository teamRepository,
    List<Player> initialPlayers = const [],
    this.simulatedDelay = const Duration(milliseconds: 120),
  }) : _teamRepository = teamRepository,
       _players = List<Player>.of(initialPlayers);

  final TeamRepository _teamRepository;
  final List<Player> _players;
  final Duration simulatedDelay;

  Future<void> _wait() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
  }

  @override
  Future<List<Player>> getPlayers({
    String? query,
    PlayerCategory? category,
    PlayerStatus? status,
  }) async {
    await _wait();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final players =
        _players.where((player) {
          if (category != null && player.category != category) return false;
          if (status != null && player.status != status) return false;
          return normalizedQuery.isEmpty ||
              player.name.toLowerCase().contains(normalizedQuery);
        }).toList()..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );
    return players;
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
    final now = DateTime.now();
    final created = player.copyWith(
      id: player.id.isEmpty
          ? 'player_${now.microsecondsSinceEpoch}'
          : player.id,
      createdAt: now,
      updatedAt: now,
    );
    _players.add(created);
    return created;
  }

  @override
  Future<Player> updatePlayer(Player player) async {
    await _wait();
    final index = _players.indexWhere((existing) => existing.id == player.id);
    if (index == -1) throw PlayerNotFoundException(player.id);
    await _validate(player);
    final updated = player.copyWith(updatedAt: DateTime.now());
    _players[index] = updated;
    return updated;
  }

  Future<void> _validate(Player player) async {
    if (player.name.trim().isEmpty) {
      throw const PlayerValidationException('Enter a player name.');
    }
    if (player.basePrice <= 0) {
      throw const PlayerValidationException(
        'Base price must be greater than zero.',
      );
    }
    if (player.assignedTeamId case final teamId?) {
      if (await _teamRepository.getTeamById(teamId) == null) {
        throw const PlayerValidationException(
          'Select an existing team or leave the assignment empty.',
        );
      }
    }
  }

  @override
  Future<bool> deletePlayer(String id) async {
    await _wait();
    final originalCount = _players.length;
    _players.removeWhere((player) => player.id == id);
    return _players.length < originalCount;
  }
}
