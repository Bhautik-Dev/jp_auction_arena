class BidIncrementTier {
  const BidIncrementTier({
    required this.minimumBid,
    required this.increment,
    this.maximumBid,
  });

  final int minimumBid;
  final int? maximumBid;
  final int increment;
}
