abstract class AppFailure {
  const AppFailure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}

class ServerFailure extends AppFailure {
  const ServerFailure({required super.message, super.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Network connection unavailable.',
    super.code,
  });
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.code});
}

class GeneralFailure extends AppFailure {
  const GeneralFailure({
    super.message = 'An unexpected failure occurred.',
    super.code,
  });
}
