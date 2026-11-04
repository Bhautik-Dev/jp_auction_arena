enum AuctionType {
  liveAuction,
  practiceDemo;

  String get label => switch (this) {
    AuctionType.liveAuction => 'Live Auction',
    AuctionType.practiceDemo => 'Practice / Demo Auction',
  };
}
