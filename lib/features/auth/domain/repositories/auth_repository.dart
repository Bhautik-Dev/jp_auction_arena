import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';

abstract interface class AuthRepository {
  Future<UserSession?> currentSession();

  Future<UserSession> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<void> signOut();

  Future<void> requestPasswordReset(String email);
}
