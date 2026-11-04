import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_permission.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/models/role_permissions.dart';
import 'package:jp_auction_arena/features/team/domain/errors/team_exceptions.dart';
import 'package:jp_auction_arena/features/team/domain/models/team.dart';
import 'package:jp_auction_arena/features/team/domain/models/team_status.dart';
import 'package:jp_auction_arena/features/team/domain/repositories/team_repository.dart';

class TeamManagementService {
  const TeamManagementService({
    required TeamRepository teamRepository,
    required AuctionRepository auctionRepository,
  }) : _teamRepository = teamRepository,
       _auctionRepository = auctionRepository;

  final TeamRepository _teamRepository;
  final AuctionRepository _auctionRepository;

  Future<List<Team>> list(
    AuthUser actor,
    String auctionId, {
    TeamStatus? status,
    String? query,
  }) async {
    await _authorize(actor, auctionId, requireEditableAuction: false);
    return _teamRepository.getTeams(
      auctionId: auctionId,
      status: status,
      query: query,
    );
  }

  Future<Team> getById(AuthUser actor, String auctionId, String teamId) async {
    await _authorize(actor, auctionId, requireEditableAuction: false);
    final team = await _teamRepository.getTeamById(teamId);
    if (team == null || team.auctionId != auctionId) {
      throw TeamValidationException(
        'Team $teamId was not found in this auction.',
      );
    }
    return team;
  }

  Future<Team> create(AuthUser actor, Team team) async {
    await _authorize(actor, team.auctionId);
    return _teamRepository.createTeam(team);
  }

  Future<Team> update(AuthUser actor, Team team) async {
    await _authorize(actor, team.auctionId);
    final existing = await _teamRepository.getTeamById(team.id);
    if (existing == null || existing.auctionId != team.auctionId) {
      throw TeamValidationException(
        'Team ${team.id} was not found in this auction.',
      );
    }
    if (existing.status == TeamStatus.archived) {
      throw const TeamValidationException(
        'Archived teams are read-only. Restore the team before editing it.',
      );
    }
    return _teamRepository.updateTeam(team);
  }

  Future<Team> updateStatus(
    AuthUser actor,
    String auctionId,
    String teamId,
    TeamStatus status,
  ) async {
    await _authorize(actor, auctionId);
    final team = await getById(actor, auctionId, teamId);
    if (team.status == TeamStatus.archived && status == TeamStatus.archived) {
      return team;
    }
    return _teamRepository.updateTeamStatus(teamId, status);
  }

  Future<List<Team>> importCsv(
    AuthUser actor,
    String auctionId,
    String csv,
  ) async {
    await _authorize(actor, auctionId);
    final rows = _parseCsv(csv);
    if (rows.length < 2) {
      throw const TeamValidationException(
        'CSV must contain a header and at least one team row.',
      );
    }
    final headers = rows.first
        .map((value) => value.trim().toLowerCase())
        .toList();
    if (headers.toSet().length != headers.length) {
      throw const TeamValidationException('CSV contains duplicate columns.');
    }
    const requiredHeaders = [
      'team_name',
      'short_name',
      'owner_name',
      'manager_name',
    ];
    if (requiredHeaders.any((header) => !headers.contains(header))) {
      throw const TeamValidationException(
        'CSV requires team_name, short_name, owner_name, and manager_name columns.',
      );
    }
    final index = {for (var i = 0; i < headers.length; i++) headers[i]: i};
    final teams = <Team>[];
    final now = DateTime.now();
    for (final row in rows.skip(1)) {
      if (row.every((value) => value.trim().isEmpty)) continue;
      if (row.length != headers.length) {
        throw const TeamValidationException(
          'CSV rows must have the same number of columns as the header.',
        );
      }
      String value(String header) =>
          index[header] == null ? '' : row[index[header]!].trim();
      teams.add(
        Team(
          id: '',
          auctionId: auctionId,
          name: value('team_name'),
          shortName: value('short_name'),
          primaryColorValue: 0xFF418BFF,
          secondaryColorValue: 0xFFAA8BFF,
          ownerName: value('owner_name'),
          managerName: value('manager_name'),
          contactEmail: value('email'),
          contactPhone: value('contact_number'),
          city: value('city'),
          description: value('description'),
          logoReference: value('logo_reference').isEmpty
              ? null
              : value('logo_reference'),
          status: TeamStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (teams.isEmpty) {
      throw const TeamValidationException('CSV contains no team records.');
    }
    return _teamRepository.importTeams(teams);
  }

  Future<String> exportCsv(AuthUser actor, String auctionId) async {
    final teams = await list(actor, auctionId);
    final rows = <List<String>>[
      const [
        'team_name',
        'short_name',
        'owner_name',
        'manager_name',
        'contact_number',
        'email',
        'city',
        'description',
        'logo_reference',
      ],
      for (final team in teams)
        [
          team.name,
          team.shortName,
          team.ownerName,
          team.managerName,
          team.contactPhone,
          team.contactEmail,
          team.city,
          team.description,
          team.logoReference ?? '',
        ],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
  }

  Future<void> _authorize(
    AuthUser actor,
    String auctionId, {
    bool requireEditableAuction = true,
  }) async {
    if (!RolePermissions.allows(actor.role, AppPermission.manageTeams) ||
        !RolePermissions.canAccessAuction(
          actor.role,
          actor.auctionIds,
          auctionId,
        )) {
      throw const TeamAccessDeniedException(
        'You do not have permission to manage teams in this auction.',
      );
    }
    final auction = await _auctionRepository.getAuctionById(auctionId);
    if (auction == null) {
      throw TeamValidationException('Auction $auctionId was not found.');
    }
    if (requireEditableAuction &&
        auction.status != AuctionStatus.draft &&
        auction.status != AuctionStatus.ready) {
      throw const TeamAuctionLockedException(
        'Teams cannot be changed after the auction becomes Live.',
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
      } else if (char == '"' && field.isEmpty) {
        quoted = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' && i + 1 < source.length && source[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(char);
      }
    }
    if (quoted) {
      throw const TeamValidationException('CSV contains an unclosed quote.');
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
