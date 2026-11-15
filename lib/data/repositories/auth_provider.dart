import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_auth_service.dart';
import '../../core/supabase/supabase_models.dart';
import '../../data/models/enums.dart';

/// Authentication state backed by Supabase Auth + `profiles` table.
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final SupabaseProfile? profile;
  final UserRole? role;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.profile,
    this.role,
  });

  // Backwards-compatible getters for existing UI code
  String get profileName => profile?.fullName ?? '';
  String get orgName => profile?.orgName ?? '';
  String get phone => profile?.phone ?? '';
  String get email => profile?.email ?? user?.email ?? '';

  bool get isProfileCreated => profile != null;

  /// Backwards-compatible: current role
  UserRole? get currentRole => role;

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    SupabaseProfile? profile,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      role: role ?? this.role,
    );
  }
}

/// Notifier that wraps Supabase Auth and keeps local state in sync.
class AuthNotifier extends Notifier<AuthState> {
  SupabaseAuthService get _service => SupabaseAuthService.instance;

  @override
  AuthState build() {
    final session = _service.currentSession;
    final user = session?.user;

    // Load profile for existing session
    if (user != null) {
      _loadProfile(user.id);
    }

    return AuthState(
      isAuthenticated: user != null,
      user: user,
      profile: null,
      role: null,
    );
  }

  Future<void> _loadProfile(String userId) async {
    final profile = await _service.getProfile(userId);
    if (profile != null) {
      final role = UserRole.fromString(profile.role);
      state = state.copyWith(
        profile: profile,
        role: role,
      );
    }
  }

  /// Sign up with email + password. Creates auth user + profiles row.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? orgName,
    String? phone,
  }) async {
    await _service.signUp(
      email: email,
      password: password,
      fullName: fullName,
      orgName: orgName,
      phone: phone,
    );
  }

  /// Sign in with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _service.signIn(email: email, password: password);
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _service.resetPassword(email);
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _service.signOut();
  }
}

/// Riverpod provider for Supabase-backed authentication.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);