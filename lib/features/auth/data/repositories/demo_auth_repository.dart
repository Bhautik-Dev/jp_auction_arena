import 'package:jp_auction_arena/features/auth/domain/errors/auth_exception.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/auth/domain/repositories/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  UserSession? _session;

  static const _accounts = <_DemoAccount>[
    _DemoAccount(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      user: AuthUser(
        id: 'demo-super-admin',
        email: 'admin@demo.jp',
        displayName: 'Demo Super Admin',
        role: AppRole.superAdmin,
        tournamentIds: {'tourn_001', 'tourn_002'},
        teamIds: {'team_001', 'team_002'},
      ),
    ),
    _DemoAccount(
      email: 'operator@demo.jp',
      password: 'DemoOperator!2026',
      user: AuthUser(
        id: 'demo-tournament-admin',
        email: 'operator@demo.jp',
        displayName: 'Demo Tournament Operator',
        role: AppRole.tournamentAdmin,
        tournamentIds: {'tourn_001'},
      ),
    ),
    _DemoAccount(
      email: 'team@demo.jp',
      password: 'DemoTeam!2026',
      user: AuthUser(
        id: 'demo-team-manager',
        email: 'team@demo.jp',
        displayName: 'Demo Team Manager',
        role: AppRole.teamManager,
        teamIds: {'team_001'},
      ),
    ),
    _DemoAccount(
      email: 'viewer@demo.jp',
      password: 'DemoViewer!2026',
      user: AuthUser(
        id: 'demo-public-viewer',
        email: 'viewer@demo.jp',
        displayName: 'Demo Public Viewer',
        role: AppRole.publicViewer,
      ),
    ),
  ];

  @override
  Future<UserSession?> currentSession() async => _session;

  @override
  Future<UserSession> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _DemoAccount? account;
    for (final candidate in _accounts) {
      if (candidate.email == normalizedEmail &&
          candidate.password == password) {
        account = candidate;
        break;
      }
    }
    if (account == null) throw const InvalidCredentialsException();

    return _session = UserSession(
      user: account.user,
      rememberMe: rememberMe,
      signedInAt: _clock(),
    );
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    throw const AuthException(
      'Password reset is unavailable for local demo accounts.',
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.email,
    required this.password,
    required this.user,
  });

  final String email;
  final String password;
  final AuthUser user;
}
