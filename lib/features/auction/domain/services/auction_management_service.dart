import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';

class AuctionManagementService {
  const AuctionManagementService({
    required AuctionRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final AuctionRepository _repository;
  final DateTime Function() _clock;

  Future<Auction> create(AuthUser actor, Auction auction) async {
    _authorizeRole(actor);
    _validate(auction);
    if (auction.status != AuctionStatus.draft) {
      throw const AuctionTransitionException(
        'New auctions must start in Draft status.',
      );
    }
    return _repository.createAuction(
      auction.copyWith(id: '', createdAt: _clock(), updatedAt: _clock()),
    );
  }

  Future<Auction> update(AuthUser actor, Auction auction) async {
    _authorizeAuction(actor, auction.id);
    final current = await _getAuction(auction.id);
    if (current.status != AuctionStatus.draft &&
        current.status != AuctionStatus.ready) {
      throw const AuctionTransitionException(
        'Only Draft or Ready auctions can be edited.',
      );
    }
    if (auction.status != current.status) {
      throw const AuctionTransitionException(
        'Change auction status using the auction status action.',
      );
    }
    _validate(auction);
    return _repository.updateAuction(auction.copyWith(updatedAt: _clock()));
  }

  Future<Auction> changeStatus(
    AuthUser actor,
    String auctionId,
    AuctionStatus nextStatus,
  ) async {
    _authorizeAuction(actor, auctionId);
    final current = await _getAuction(auctionId);
    if (nextStatus == AuctionStatus.ready || nextStatus == AuctionStatus.live) {
      _validate(current);
    }
    if (!_canTransition(current.status, nextStatus)) {
      throw AuctionTransitionException(
        'Cannot change status from ${current.status.label} to '
        '${nextStatus.label}.',
      );
    }
    return _repository.updateAuctionStatus(auctionId, nextStatus);
  }

  Future<Auction> getById(AuthUser actor, String id) async {
    _authorizeRole(actor);
    _authorizeAuction(actor, id);
    return _getAuction(id);
  }

  Future<List<Auction>> list(AuthUser actor) async {
    _authorizeRole(actor);
    final auctions = await _repository.getAuctions();
    if (actor.role == AppRole.superAdmin) return auctions;
    return auctions
        .where((item) => actor.auctionIds.contains(item.id))
        .toList();
  }

  static bool canTransition(AuctionStatus current, AuctionStatus next) =>
      _canTransition(current, next);

  static bool _canTransition(AuctionStatus current, AuctionStatus next) =>
      switch (current) {
        AuctionStatus.draft => next == AuctionStatus.ready,
        AuctionStatus.ready =>
          next == AuctionStatus.draft || next == AuctionStatus.live,
        AuctionStatus.live =>
          next == AuctionStatus.paused || next == AuctionStatus.completed,
        AuctionStatus.paused =>
          next == AuctionStatus.live || next == AuctionStatus.completed,
        AuctionStatus.completed => next == AuctionStatus.archived,
        AuctionStatus.archived => next == AuctionStatus.completed,
      };

  Future<Auction> _getAuction(String id) async {
    final auction = await _repository.getAuctionById(id);
    if (auction == null) {
      throw AuctionValidationException('Auction $id was not found.');
    }
    return auction;
  }

  void _authorizeRole(AuthUser actor) {
    if (actor.role != AppRole.superAdmin &&
        actor.role != AppRole.tournamentAdmin) {
      throw const AuctionAuthorizationException(
        'Only admins and auction operators can manage auctions.',
      );
    }
  }

  void _authorizeAuction(AuthUser actor, String id) {
    _authorizeRole(actor);
    if (actor.role == AppRole.tournamentAdmin &&
        !actor.auctionIds.contains(id)) {
      throw const AuctionAuthorizationException(
        'You are not assigned to manage this auction.',
      );
    }
  }

  void _validate(Auction auction) {
    if (auction.name.trim().isEmpty) {
      throw const AuctionValidationException('Auction name is required.');
    }
    final today = _dateOnly(_clock());
    if (_dateOnly(auction.auctionDate).isBefore(today)) {
      throw const AuctionValidationException(
        'Auction date cannot be in the past.',
      );
    }
    if (auction.startTimeMinutes < 0 || auction.startTimeMinutes >= 1440) {
      throw const AuctionValidationException(
        'Auction start time must be within a day.',
      );
    }
    if (auction.maxTeams < 2) {
      throw const AuctionValidationException(
        'Maximum number of teams must be at least 2.',
      );
    }
    if (auction.minPlayersPerTeam < 1 ||
        auction.maxPlayersPerTeam < auction.minPlayersPerTeam) {
      throw const AuctionValidationException(
        'Player limits must be positive and minimum cannot exceed maximum.',
      );
    }
    if (!auction.totalPursePerTeam.isFinite || auction.totalPursePerTeam <= 0) {
      throw const AuctionValidationException(
        'Team auction purse must be greater than zero.',
      );
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(auction.baseCurrency)) {
      throw const AuctionValidationException(
        'Base currency must be a three-letter uppercase currency code.',
      );
    }
    if (auction.organizerName.trim().isEmpty) {
      throw const AuctionValidationException('Organizer name is required.');
    }
    if (auction.cricketFormat == CricketFormat.custom &&
        (auction.customFormat?.trim().isEmpty ?? true)) {
      throw const AuctionValidationException(
        'Enter a name for the custom cricket format.',
      );
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
