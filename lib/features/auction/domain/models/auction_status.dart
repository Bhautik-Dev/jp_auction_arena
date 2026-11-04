enum AuctionStatus {
  draft,
  ready,
  live,
  paused,
  completed,
  archived;

  String get label => switch (this) {
    AuctionStatus.draft => 'Draft',
    AuctionStatus.ready => 'Ready',
    AuctionStatus.live => 'Live',
    AuctionStatus.paused => 'Paused',
    AuctionStatus.completed => 'Completed',
    AuctionStatus.archived => 'Archived',
  };
}
