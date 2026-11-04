import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.tournamentIds = const {},
    this.teamIds = const {},
  });

  final String id;
  final String email;
  final String displayName;
  final AppRole role;
  final Set<String> tournamentIds;
  final Set<String> teamIds;

  AuthUser copyWith({
    String? displayName,
    Set<String>? tournamentIds,
    Set<String>? teamIds,
  }) => AuthUser(
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    role: role,
    tournamentIds: tournamentIds ?? this.tournamentIds,
    teamIds: teamIds ?? this.teamIds,
  );
}

class UserSession {
  const UserSession({
    required this.user,
    required this.rememberMe,
    required this.signedInAt,
  });

  final AuthUser user;
  final bool rememberMe;
  final DateTime signedInAt;
}
