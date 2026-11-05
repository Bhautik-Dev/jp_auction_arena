enum AuctionStatus {
  draft,
  live,
  paused,
  completed,
  archived;

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
      case AuctionStatus.archived:
        return 'Archived';
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


enum UserRole {
  admin,
  operator,
  viewer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full access: manage auctions, teams, players, settings, and live desk.';
      case UserRole.operator:
        return 'Live operator: conduct live hammer auction and place bids.';
      case UserRole.viewer:
        return 'Read-only: view auction results, projector stage, and public stats.';
    }
  }

  bool get canManageEverything => this == UserRole.admin;
  bool get canRunLiveAuction => this == UserRole.admin || this == UserRole.operator;
  bool get isReadOnly => this == UserRole.viewer;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => UserRole.admin,
    );
  }
}
