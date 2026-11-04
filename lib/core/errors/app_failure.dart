abstract class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure() : super('Something went wrong. Please try again.');
}

String userFacingError(Object error) {
  if (error is AppFailure) {
    return error.message;
  }
  return const UnexpectedFailure().message;
}
