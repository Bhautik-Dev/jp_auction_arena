sealed class PlayerException implements Exception {
  const PlayerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlayerValidationException extends PlayerException {
  const PlayerValidationException(super.message);
}
