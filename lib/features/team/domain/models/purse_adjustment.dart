class PurseAdjustment {
  const PurseAdjustment({
    required this.auctionId,
    required this.teamId,
    required this.amount,
    required this.reason,
    required this.actorId,
    required this.createdAt,
  });

  final String auctionId;
  final String teamId;
  final int amount;
  final String reason;
  final String actorId;
  final DateTime createdAt;
}
