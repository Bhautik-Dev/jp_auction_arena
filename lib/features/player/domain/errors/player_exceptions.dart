sealed class PlayerException implements Exception {
  const PlayerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlayerValidationException extends PlayerException {
  const PlayerValidationException(super.message);
}

class PlayerAccessDeniedException extends PlayerException {
  const PlayerAccessDeniedException(super.message);
}

class PlayerAuctionLockedException extends PlayerException {
  const PlayerAuctionLockedException(super.message);
}

class PlayerDeletionBlockedException extends PlayerException {
  const PlayerDeletionBlockedException(super.message);
}
