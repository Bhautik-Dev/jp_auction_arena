import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/tournament/domain/errors/tournament_exceptions.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament.dart';
import 'package:jp_auction_arena/features/tournament/domain/models/tournament_status.dart';
import 'package:jp_auction_arena/features/tournament/domain/repositories/tournament_repository.dart';

class TournamentManagementService {
  const TournamentManagementService({
    required TournamentRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final TournamentRepository _repository;
  final DateTime Function() _clock;

  Future<Tournament> create(AuthUser actor, Tournament tournament) async {
    _authorize(actor, creating: true);
    _validate(tournament);
    if (tournament.status != TournamentStatus.draft &&
        tournament.status != TournamentStatus.upcoming) {
      throw const TournamentTransitionException(
        'New tournaments must start as Draft or Upcoming.',
      );
    }
    return _repository.createTournament(
      tournament.copyWith(id: '', createdAt: _clock(), updatedAt: _clock()),
    );
  }

  Future<Tournament> update(AuthUser actor, Tournament tournament) async {
    _authorize(actor);
    final current = await _getAuthorized(actor, tournament.id);
    if (current.status == TournamentStatus.archived) {
      throw const TournamentTransitionException(
        'Archived tournaments are read-only. Restore the tournament first.',
      );
    }
    if (current.status != tournament.status) {
      throw const TournamentTransitionException(
        'Change tournament status using the status management action.',
      );
    }
    _validate(tournament);
    return _repository.updateTournament(
      tournament.copyWith(updatedAt: _clock()),
    );
  }

  Future<Tournament> changeStatus(
    AuthUser actor,
    String tournamentId,
    TournamentStatus nextStatus,
  ) async {
    _authorize(actor);
    final current = await _getAuthorized(actor, tournamentId);
    if (!_canTransition(current.status, nextStatus)) {
      throw TournamentTransitionException(
        'Cannot change status from ${current.status.label} to '
        '${nextStatus.label}.',
      );
    }
    return _repository.updateTournamentStatus(tournamentId, nextStatus);
  }

  Future<bool> delete(AuthUser actor, String tournamentId) async {
    _authorize(actor);
    final tournament = await _getAuthorized(actor, tournamentId);
    if (tournament.hasAuctionTransactions) {
      throw const TournamentArchiveRequiredException(
        'This tournament has auction transactions and must be archived, not deleted.',
      );
    }
    if (tournament.status == TournamentStatus.active ||
        tournament.status == TournamentStatus.completed ||
        tournament.status == TournamentStatus.archived) {
      throw const TournamentArchiveRequiredException(
        'Active, completed, and archived tournaments cannot be deleted. '
        'Use the status and archive workflow.',
      );
    }
    return _repository.deleteTournament(tournamentId);
  }

  Future<Tournament> getById(AuthUser actor, String id) async {
    _authorize(actor);
    return _getAuthorized(actor, id);
  }

  Future<List<Tournament>> list(AuthUser actor) async {
    _authorize(actor);
    final tournaments = await _repository.getTournaments();
    if (actor.role == AppRole.superAdmin) return tournaments;
    return tournaments
        .where((item) => actor.tournamentIds.contains(item.id))
        .toList();
  }

  Future<Tournament> _getAuthorized(AuthUser actor, String id) async {
    final tournament = await _repository.getTournamentById(id);
    if (tournament == null) {
      throw TournamentValidationException('Tournament $id was not found.');
    }
    if (actor.role == AppRole.tournamentAdmin &&
        !actor.tournamentIds.contains(id)) {
      throw const TournamentAuthorizationException(
        'You are not assigned to manage this tournament.',
      );
    }
    return tournament;
  }

  void _authorize(AuthUser actor, {bool creating = false}) {
    if (actor.role == AppRole.superAdmin) return;
    if (actor.role == AppRole.tournamentAdmin &&
        (!creating || actor.tournamentIds.isNotEmpty)) {
      return;
    }
    throw const TournamentAuthorizationException(
      'Your role is not permitted to manage tournaments.',
    );
  }

  static bool canTransition(TournamentStatus current, TournamentStatus next) =>
      _canTransition(current, next);

  static bool _canTransition(TournamentStatus current, TournamentStatus next) {
    if (current == next) return false;
    return switch (current) {
      TournamentStatus.draft =>
        next == TournamentStatus.upcoming || next == TournamentStatus.cancelled,
      TournamentStatus.upcoming =>
        next == TournamentStatus.draft ||
            next == TournamentStatus.active ||
            next == TournamentStatus.cancelled,
      TournamentStatus.active =>
        next == TournamentStatus.completed ||
            next == TournamentStatus.cancelled,
      TournamentStatus.completed => next == TournamentStatus.archived,
      TournamentStatus.archived => next == TournamentStatus.completed,
      TournamentStatus.cancelled => next == TournamentStatus.draft,
    };
  }

  static void _validate(Tournament tournament) {
    if (tournament.name.trim().isEmpty) {
      throw const TournamentValidationException('Tournament name is required.');
    }
    if (tournament.city.trim().isEmpty) {
      throw const TournamentValidationException(
        'Tournament location is required.',
      );
    }
    if (tournament.format.trim().isEmpty) {
      throw const TournamentValidationException(
        'Tournament format is required.',
      );
    }
    if (tournament.organizerName.trim().isEmpty) {
      throw const TournamentValidationException('Organizer name is required.');
    }
    if (tournament.contactDetails.trim().isEmpty) {
      throw const TournamentValidationException(
        'Contact details are required.',
      );
    }
    if (tournament.maxTeams < 2) {
      throw const TournamentValidationException(
        'At least two participating teams must be allowed.',
      );
    }
    if (tournament.minSquadSize < 1 ||
        tournament.maxSquadSize < tournament.minSquadSize) {
      throw const TournamentValidationException(
        'Squad limits must be positive and the minimum cannot exceed the maximum.',
      );
    }
    if (_dateOnly(
      tournament.startDate,
    ).isAfter(_dateOnly(tournament.endDate))) {
      throw const TournamentValidationException(
        'Tournament end date must be on or after the start date.',
      );
    }
    final registrationStart = tournament.registrationStartDate;
    final registrationEnd = tournament.registrationClosingDate;
    if (registrationStart == null || registrationEnd == null) {
      throw const TournamentValidationException(
        'Registration start and closing dates are required.',
      );
    }
    final registrationStartDay = _dateOnly(registrationStart);
    final registrationEndDay = _dateOnly(registrationEnd);
    if (registrationStartDay.isAfter(registrationEndDay)) {
      throw const TournamentValidationException(
        'Registration closing date must be on or after registration start.',
      );
    }
    if (registrationEndDay.isAfter(_dateOnly(tournament.startDate))) {
      throw const TournamentValidationException(
        'Registration must close on or before the tournament start date.',
      );
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
