class AuctionReadinessItem {
  const AuctionReadinessItem({
    required this.label,
    required this.details,
    required this.isComplete,
    this.isBlocking = true,
  });

  final String label;
  final String details;
  final bool isComplete;
  final bool isBlocking;
}
