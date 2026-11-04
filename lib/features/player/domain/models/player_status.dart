enum PlayerStatus {
  available,
  sold,
  unsold,
  unavailable;

  String get label => switch (this) {
    PlayerStatus.available => 'Available',
    PlayerStatus.sold => 'Sold',
    PlayerStatus.unsold => 'Unsold',
    PlayerStatus.unavailable => 'Unavailable',
  };
}
