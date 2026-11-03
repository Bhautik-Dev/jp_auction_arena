class TeamException implements Exception {
  const TeamException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TeamNotFoundException extends TeamException {
  const TeamNotFoundException(String id) : super('Team "$id" was not found.');
}

class TeamValidationException extends TeamException {
  const TeamValidationException(super.message);
}

class TeamCapacityExceededException extends TeamException {
  const TeamCapacityExceededException({
    required this.maxTeams,
    required this.tournamentName,
  }) : super('$tournamentName already has its maximum of $maxTeams teams.');

  final int maxTeams;
  final String tournamentName;
}

class TeamDeletionBlockedException extends TeamException {
  const TeamDeletionBlockedException(super.message);
}
