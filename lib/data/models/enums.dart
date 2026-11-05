enum AuctionStatus {
  draft,
  live,
  paused,
  completed;

  String get displayName {
    switch (this) {
      case AuctionStatus.draft:
        return 'Draft';
      case AuctionStatus.live:
        return 'Live';
      case AuctionStatus.paused:
        return 'Paused';
      case AuctionStatus.completed:
        return 'Completed';
    }
  }

  static AuctionStatus fromString(String? value) {
    return AuctionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => AuctionStatus.draft,
    );
  }
}

enum AuctionMode {
  manual,
  auto,
  categoryWise;

  String get displayName {
    switch (this) {
      case AuctionMode.manual:
        return 'Manual';
      case AuctionMode.auto:
        return 'Auto';
      case AuctionMode.categoryWise:
        return 'Category-wise';
    }
  }

  static AuctionMode fromString(String? value) {
    return AuctionMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => AuctionMode.manual,
    );
  }
}

enum PlayerStatus {
  available,
  sold,
  unsold,
  live;

  String get displayName {
    switch (this) {
      case PlayerStatus.available:
        return 'Available';
      case PlayerStatus.sold:
        return 'Sold';
      case PlayerStatus.unsold:
        return 'Unsold';
      case PlayerStatus.live:
        return 'In Auction';
    }
  }

  static PlayerStatus fromString(String? value) {
    return PlayerStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => PlayerStatus.available,
    );
  }
}
