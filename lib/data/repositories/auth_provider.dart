import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/enums.dart';

/// Simple non-auth state — always authenticated as admin.
/// Authentication has been removed from the app; this provider
/// keeps the UI working without any sign-in requirement.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserRole? role;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.role,
  });

  const AuthState.loading()
      : isAuthenticated = false,
        isLoading = true,
        role = null;

  String get profileName => 'JP Arena User';
  String get orgName => '';
  String get phone => '';
  String get email => '';

  bool get isProfileCreated => true;

  UserRole? get currentRole => role;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Always authenticated as admin — no login required
    return const AuthState(
      isAuthenticated: true,
      isLoading: false,
      role: UserRole.admin,
    );
  }
}

/// Riverpod provider for authentication state (always authenticated).
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
