import 'package:jp_auction_arena/features/auction/domain/errors/auction_exceptions.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_status.dart';
import 'package:jp_auction_arena/features/auction/domain/models/auction_type.dart';
import 'package:jp_auction_arena/features/auction/domain/models/cricket_format.dart';
import 'package:jp_auction_arena/features/auction/domain/repositories/auction_repository.dart';
import 'package:jp_auction_arena/features/auction/domain/services/auction_management_service.dart';

class InMemoryAuctionRepository implements AuctionRepository {
  InMemoryAuctionRepository({List<Auction>? initialAuctions})
    : _auctions = List.of(initialAuctions ?? demoAuctions);

  final List<Auction> _auctions;
  int _nextId = 1;

  @override
  Future<List<Auction>> getAuctions({
    AuctionStatus? status,
    String? query,
  }) async {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final result =
        _auctions.where((auction) {
          final matchesStatus = status == null || auction.status == status;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              '${auction.name} ${auction.location} ${auction.organizerName}'
                  .toLowerCase()
                  .contains(normalizedQuery);
          return matchesStatus && matchesQuery;
        }).toList()..sort(
          (first, second) => first.auctionDate.compareTo(second.auctionDate),
        );
    return List.unmodifiable(result);
  }

  @override
  Future<Auction?> getAuctionById(String id) async {
    for (final auction in _auctions) {
      if (auction.id == id) return auction;
    }
    return null;
  }

  @override
  Future<Auction> createAuction(Auction auction) async {
    if (auction.status != AuctionStatus.draft) {
      throw const AuctionTransitionException(
        'New auctions must start in Draft status.',
      );
    }
    final created = auction.copyWith(id: 'auction_${_nextId++}');
    _auctions.add(created);
    return created;
  }

  @override
  Future<Auction> updateAuction(Auction auction) async {
    final index = _auctions.indexWhere((item) => item.id == auction.id);
    if (index < 0) {
      throw AuctionValidationException('Auction ${auction.id} was not found.');
    }
    final current = _auctions[index];
    if (current.status != AuctionStatus.draft &&
        current.status != AuctionStatus.ready) {
      throw const AuctionTransitionException(
        'Only Draft or Ready auctions can be edited.',
      );
    }
    if (current.status != auction.status) {
      throw const AuctionTransitionException(
        'Use status management to change auction status.',
      );
    }
    _auctions[index] = auction;
    return auction;
  }

  @override
  Future<Auction> updateAuctionStatus(String id, AuctionStatus status) async {
    final index = _auctions.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw AuctionValidationException('Auction $id was not found.');
    }
    final current = _auctions[index];
    if (!AuctionManagementService.canTransition(current.status, status)) {
      throw AuctionTransitionException(
        'Cannot change status from ${current.status.label} to ${status.label}.',
      );
    }
    if (status == AuctionStatus.live &&
        _auctions.any(
          (item) => item.id != id && item.status == AuctionStatus.live,
        )) {
      throw const AuctionTransitionException(
        'Only one auction can be Live at a time.',
      );
    }
    final updated = current.copyWith(status: status, updatedAt: DateTime.now());
    _auctions[index] = updated;
    return updated;
  }
}

final demoAuctions = <Auction>[
  Auction(
    id: 'auction_001',
    name: 'JP Premier League Player Auction 2026',
    description: 'Sample auction record for the local demo.',
    auctionDate: DateTime(2026, 12, 12),
    startTimeMinutes: 600,
    location: 'Ahmedabad',
    auctionType: AuctionType.liveAuction,
    cricketFormat: CricketFormat.t20,
    maxTeams: 8,
    maxPlayersPerTeam: 18,
    minPlayersPerTeam: 11,
    totalPursePerTeam: 10000000,
    baseCurrency: 'INR',
    status: AuctionStatus.ready,
    organizerName: 'JP AUCTION ARENA Demo',
    contactDetails: 'demo@jp-auction-arena.invalid',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  ),
  Auction(
    id: 'auction_002',
    name: 'Practice Auction - Evening Session',
    description: 'Synthetic practice auction; not connected to live bidding.',
    auctionDate: DateTime(2026, 12, 20),
    startTimeMinutes: 840,
    auctionType: AuctionType.practiceDemo,
    cricketFormat: CricketFormat.t10,
    maxTeams: 6,
    maxPlayersPerTeam: 15,
    minPlayersPerTeam: 8,
    totalPursePerTeam: 5000000,
    baseCurrency: 'INR',
    status: AuctionStatus.draft,
    organizerName: 'JP AUCTION ARENA Demo',
    createdAt: DateTime(2026, 10, 5),
    updatedAt: DateTime(2026, 10, 5),
  ),
  Auction(
    id: 'auction_003',
    name: 'Demo Champions Auction 2025',
    description: 'Completed sample record retained for history.',
    auctionDate: DateTime(2025, 11, 12),
    startTimeMinutes: 600,
    auctionType: AuctionType.liveAuction,
    cricketFormat: CricketFormat.odi,
    maxTeams: 8,
    maxPlayersPerTeam: 16,
    minPlayersPerTeam: 11,
    totalPursePerTeam: 8000000,
    baseCurrency: 'INR',
    status: AuctionStatus.completed,
    organizerName: 'JP AUCTION ARENA Demo',
    createdAt: DateTime(2025, 8, 1),
    updatedAt: DateTime(2025, 11, 12),
  ),
];
