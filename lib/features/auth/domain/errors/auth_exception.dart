import 'package:jp_auction_arena/core/errors/app_failure.dart';

class AuthException extends AppFailure {
  const AuthException(super.message);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Email or password is incorrect.');
}
