import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/models/role_permissions.dart';
import 'package:jp_auction_arena/features/player/domain/errors/player_exceptions.dart';
import 'package:jp_auction_arena/features/player/domain/models/player.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_category.dart';
import 'package:jp_auction_arena/features/player/domain/models/player_status.dart';
import 'package:jp_auction_arena/features/player/domain/repositories/player_repository.dart';

class PlayerManagementService {
  const PlayerManagementService({
    required PlayerRepository playerRepository,
    required AuctionRepository auctionRepository,
  }) : _playerRepository = playerRepository,
       _auctionRepository = auctionRepository;

  final PlayerRepository _playerRepository;
  final AuctionRepository _auctionRepository;

  Future<List<Player>> list(
    AuthUser actor,
    String auctionId, {
    String? query,
    PlayerCategory? category,
    PlayerStatus? status,
  }) async {
    await _authorize(actor, auctionId, requireEditableAuction: false);
    return _playerRepository.getPlayers(
      auctionId: auctionId,
      query: query,
      category: category,
      status: status,
    );
  }

  Future<Player> getById(
    AuthUser actor,
    String auctionId,
    String playerId,
  ) async {
    await _authorize(actor, auctionId, requireEditableAuction: false);
    final player = await _playerRepository.getPlayerById(playerId);
    if (player == null || player.auctionId != auctionId) {
      throw PlayerValidationException(
        'Player $playerId was not found in this auction.',
      );
    }
    return player;
  }

  Future<Player> create(AuthUser actor, Player player) async {
    await _authorize(actor, player.auctionId);
    if (player.auctionId.isEmpty) {
      throw const PlayerValidationException(
        'Players must be registered to an auction.',
      );
    }
    if (player.status != PlayerStatus.available ||
        player.assignedTeamId != null) {
      throw const PlayerValidationException(
        'New players must start as available and unassigned.',
      );
    }
    await _validateBasePrice(player);
    return _playerRepository.createPlayer(player);
  }

  Future<Player> update(AuthUser actor, Player player) async {
    await _authorize(actor, player.auctionId);
    await _validateBasePrice(player);
    final existing = await _playerRepository.getPlayerById(player.id);
    if (existing == null || existing.auctionId != player.auctionId) {
      throw PlayerValidationException(
        'Player ${player.id} was not found in this auction.',
      );
    }
    if (existing.status == PlayerStatus.sold ||
        existing.status == PlayerStatus.unsold) {
      throw const PlayerAuctionLockedException(
        'Players with an auction result cannot be edited.',
      );
    }
    if (player.status != existing.status ||
        player.assignedTeamId != existing.assignedTeamId ||
        player.purchasePrice != existing.purchasePrice) {
      throw const PlayerValidationException(
        'Player status, team assignment, and purchase price are managed by auction results.',
      );
    }
    return _playerRepository.updatePlayer(player);
  }

  Future<Player> updateAvailability(
    AuthUser actor,
    String auctionId,
    String playerId,
    PlayerStatus status,
  ) async {
    if (status != PlayerStatus.available &&
        status != PlayerStatus.unavailable) {
      throw const PlayerValidationException(
        'Only availability can be changed before the auction.',
      );
    }
    await _authorize(actor, auctionId);
    final current = await getById(actor, auctionId, playerId);
    if (current.status == PlayerStatus.sold ||
        current.status == PlayerStatus.unsold) {
      throw const PlayerAuctionLockedException(
        'Auction result status cannot be changed in player management.',
      );
    }
    return _playerRepository.updatePlayer(
      current.copyWith(status: status, updatedAt: DateTime.now()),
    );
  }

  Future<bool> delete(AuthUser actor, String auctionId, String playerId) async {
    await _authorize(actor, auctionId);
    final player = await getById(actor, auctionId, playerId);
    if (player.status != PlayerStatus.available ||
        player.assignedTeamId != null) {
      throw const PlayerDeletionBlockedException(
        'Players with an auction result or team assignment cannot be deleted.',
      );
    }
    return _playerRepository.deletePlayer(playerId);
  }

  Future<List<Player>> importCsv(
    AuthUser actor,
    String auctionId,
    String csv,
  ) async {
    await _authorize(actor, auctionId);
    final rows = _parseCsv(csv);
    if (rows.length < 2) {
      throw const PlayerValidationException(
        'CSV must contain a header and at least one player row.',
      );
    }
    final headers = rows.first
        .map((value) => value.trim().toLowerCase())
        .toList();
    if (headers.toSet().length != headers.length) {
      throw const PlayerValidationException('CSV contains duplicate columns.');
    }
    const requiredHeaders = ['player_name', 'category', 'base_price'];
    if (requiredHeaders.any((header) => !headers.contains(header))) {
      throw const PlayerValidationException(
        'CSV requires player_name, category, and base_price columns.',
      );
    }
    final index = {for (var i = 0; i < headers.length; i++) headers[i]: i};
    final players = <Player>[];
    final now = DateTime.now();
    for (final row in rows.skip(1)) {
      if (row.every((value) => value.trim().isEmpty)) continue;
      if (row.length != headers.length) {
        throw const PlayerValidationException(
          'CSV rows must have the same number of columns as the header.',
        );
      }
      String value(String header) =>
          index[header] == null ? '' : row[index[header]!].trim();
      final categoryValue = value('category').toLowerCase();
      final category = PlayerCategory.values.where(
        (item) =>
            item.name.toLowerCase() == categoryValue ||
            item.label.toLowerCase() == categoryValue,
      );
      final basePrice = int.tryParse(value('base_price'));
      final ageText = value('age');
      final age = ageText.isEmpty ? null : int.tryParse(ageText);
      final overseasText = value('is_overseas').toLowerCase();
      final isOverseas = switch (overseasText) {
        '' || 'false' || 'no' || '0' => false,
        'true' || 'yes' || '1' => true,
        _ => throw const PlayerValidationException(
          'CSV contains an invalid is_overseas value.',
        ),
      };
      int optionalNonNegative(String header) {
        final text = value(header);
        if (text.isEmpty) return 0;
        final parsed = int.tryParse(text);
        if (parsed == null || parsed < 0) {
          throw const PlayerValidationException(
            'CSV contains an invalid player statistic.',
          );
        }
        return parsed;
      }

      if (category.isEmpty ||
          basePrice == null ||
          (ageText.isNotEmpty && age == null)) {
        throw const PlayerValidationException(
          'CSV contains an invalid category, age, or base price.',
        );
      }
      players.add(
        Player(
          id: '',
          auctionId: auctionId,
          name: value('player_name'),
          imageReference: value('image_reference').isEmpty
              ? null
              : value('image_reference'),
          category: category.first,
          battingStyle: value('batting_style'),
          bowlingStyle: value('bowling_style'),
          basePrice: basePrice,
          contactNumber: value('contact_number').isEmpty
              ? null
              : value('contact_number'),
          status: PlayerStatus.available,
          assignedTeamId: null,
          age: age,
          matchesPlayed: optionalNonNegative('matches_played'),
          runsScored: optionalNonNegative('runs_scored'),
          wicketsTaken: optionalNonNegative('wickets_taken'),
          isOverseas: isOverseas,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (players.isEmpty) {
      throw const PlayerValidationException('CSV contains no player records.');
    }
    for (final player in players) {
      await _validateBasePrice(player);
    }
    return _playerRepository.importPlayers(players);
  }

  Future<void> _validateBasePrice(Player player) async {
    if (player.basePrice <= 0) {
      throw const PlayerValidationException(
        'Player base price must be greater than zero.',
      );
    }
    final auction = await _auctionRepository.getAuctionById(player.auctionId);
    if (auction == null) {
      throw PlayerValidationException(
        'Auction ${player.auctionId} was not found.',
      );
    }
    if (player.basePrice > auction.totalPursePerTeam) {
      throw const PlayerValidationException(
        'Player base price cannot exceed the auction team purse.',
      );
    }
  }

  Future<String> exportCsv(AuthUser actor, String auctionId) async {
    final players = await list(actor, auctionId);
    final rows = <List<String>>[
      const [
        'player_name',
        'category',
        'batting_style',
        'bowling_style',
        'base_price',
        'age',
        'contact_number',
        'image_reference',
        'matches_played',
        'runs_scored',
        'wickets_taken',
        'is_overseas',
        'status',
      ],
      for (final player in players)
        [
          player.name,
          player.category.name,
          player.battingStyle,
          player.bowlingStyle,
          '${player.basePrice}',
          player.age?.toString() ?? '',
          player.contactNumber ?? '',
          player.imageReference ?? '',
          '${player.matchesPlayed}',
          '${player.runsScored}',
          '${player.wicketsTaken}',
          '${player.isOverseas}',
          player.status.name,
        ],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
  }

  Future<void> _authorize(
    AuthUser actor,
    String auctionId, {
    bool requireEditableAuction = true,
  }) async {
    if (!RolePermissions.allows(actor.role, AppPermission.managePlayers) ||
        !RolePermissions.canAccessAuction(
          actor.role,
          actor.auctionIds,
          auctionId,
        )) {
      throw const PlayerAccessDeniedException(
        'You do not have permission to manage players in this auction.',
      );
    }
    final auction = await _auctionRepository.getAuctionById(auctionId);
    if (auction == null) {
      throw PlayerValidationException('Auction $auctionId was not found.');
    }
    if (requireEditableAuction &&
        auction.status != AuctionStatus.draft &&
        auction.status != AuctionStatus.ready) {
      throw const PlayerAuctionLockedException(
        'Players cannot be changed after the auction becomes Live.',
      );
    }
  }

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  List<List<String>> _parseCsv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (quoted) {
        if (char == '"' && i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else if (char == '"') {
          quoted = false;
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        if (field.isNotEmpty) {
          throw const PlayerValidationException(
            'CSV contains an invalid quote.',
          );
        }
        quoted = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (char == '\n') {
        row.add(field.toString().replaceFirst(RegExp(r'\r$'), ''));
        rows.add(row);
        row = <String>[];
        field.clear();
      } else {
        field.write(char);
      }
    }
    if (quoted) {
      throw const PlayerValidationException('CSV contains an unclosed quote.');
    }
    row.add(field.toString());
    if (row.any((value) => value.isNotEmpty) || rows.isEmpty) rows.add(row);
    return rows;
  }
}
