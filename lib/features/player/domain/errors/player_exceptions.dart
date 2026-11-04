class PlayerException implements Exception {
  const PlayerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlayerNotFoundException extends PlayerException {
  const PlayerNotFoundException(String id)
    : super('Player "$id" was not found.');
}

class PlayerValidationException extends PlayerException {
  const PlayerValidationException(super.message);
}
