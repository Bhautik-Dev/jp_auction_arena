sealed class TeamException implements Exception {
  const TeamException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TeamValidationException extends TeamException {
  const TeamValidationException(super.message);
}

class TeamCapacityExceededException extends TeamException {
  const TeamCapacityExceededException(super.message);
}

class TeamDeletionBlockedException extends TeamException {
  const TeamDeletionBlockedException(super.message);
}

class TeamAccessDeniedException extends TeamException {
  const TeamAccessDeniedException(super.message);
}

class TeamAuctionLockedException extends TeamException {
  const TeamAuctionLockedException(super.message);
}
