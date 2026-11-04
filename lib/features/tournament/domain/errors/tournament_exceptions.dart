class TournamentValidationException implements Exception {
  const TournamentValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TournamentAuthorizationException implements Exception {
  const TournamentAuthorizationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TournamentTransitionException implements Exception {
  const TournamentTransitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TournamentArchiveRequiredException implements Exception {
  const TournamentArchiveRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}
