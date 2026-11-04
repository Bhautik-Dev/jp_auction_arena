import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DemoAuthRepository(),
);

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionController, UserSession?>(
      AuthSessionController.new,
    );

class AuthSessionController extends AsyncNotifier<UserSession?> {
  late AuthRepository _repository;

  @override
  Future<UserSession?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return _repository.currentSession();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = await AsyncValue.guard(
      () => _repository.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
      ),
    );
  }

  Future<void> signOut() async {
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
  }

  Future<void> requestPasswordReset(String email) =>
      _repository.requestPasswordReset(email);

  void assignTournament(String tournamentId) {
    final session = state.whenOrNull(data: (value) => value);
    if (session == null ||
        (session.user.role != AppRole.superAdmin &&
            session.user.role != AppRole.tournamentAdmin)) {
      return;
    }
    state = AsyncData(
      UserSession(
        user: session.user.copyWith(
          tournamentIds: {...session.user.tournamentIds, tournamentId},
        ),
        rememberMe: session.rememberMe,
        signedInAt: session.signedInAt,
      ),
    );
  }

  void assignAuction(String auctionId) {
    final session = state.whenOrNull(data: (value) => value);
    if (session == null ||
        (session.user.role != AppRole.superAdmin &&
            session.user.role != AppRole.tournamentAdmin)) {
      return;
    }
    state = AsyncData(
      UserSession(
        user: session.user.copyWith(
          auctionIds: {...session.user.auctionIds, auctionId},
        ),
        rememberMe: session.rememberMe,
        signedInAt: session.signedInAt,
      ),
    );
  }
}
