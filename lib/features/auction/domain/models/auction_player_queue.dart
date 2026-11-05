class AuctionPlayerQueue {
  const AuctionPlayerQueue({
    required this.auctionId,
    required this.playerIds,
    required this.updatedAt,
  });

  final String auctionId;
  final List<String> playerIds;
  final DateTime updatedAt;
}
