enum BidIncrementMode {
  fixed,
  tiered;

  String get label => switch (this) {
    BidIncrementMode.fixed => 'Fixed increment',
    BidIncrementMode.tiered => 'Tiered increments',
  };
}
