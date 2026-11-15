import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_auth_service.dart';
import '../../core/supabase/supabase_models.dart';
import '../../data/models/enums.dart';

/// Authentication state backed by Supabase Auth + `profiles` table.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final SupabaseProfile? profile;
  final UserRole? role;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.profile,
    this.role,
  });

  /// Initial loading state — auth is still being checked.
  const AuthState.loading()
      : isAuthenticated = false,
        isLoading = true,
        user = null,
        profile = null,
        role = null;

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
    bool? isLoading,
    User? user,
    SupabaseProfile? profile,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      role: role ?? this.role,
    );
  }
}

/// Tracks email rate-limit cooldown state to prevent hammering Supabase's
/// email service when rate limits are hit.
class EmailRateLimiter {
  EmailRateLimiter._();
  static final EmailRateLimiter _instance = EmailRateLimiter._();
  static EmailRateLimiter get instance => _instance;

  /// Timestamp when the rate limit cooldown expires, or null if none active.
  DateTime? _cooldownUntil;

  /// Minimum cooldown period after a rate limit error (10 minutes).
  static const Duration _cooldownDuration = Duration(minutes: 10);

  /// Whether email operations are currently rate-limited.
  bool get isRateLimited {
    if (_cooldownUntil == null) return false;
    return DateTime.now().isBefore(_cooldownUntil!);
  }

  /// Seconds remaining until the cooldown expires, or 0 if not limited.
  int get secondsRemaining {
    if (_cooldownUntil == null) return 0;
    final remaining = _cooldownUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record a rate-limit error and start the cooldown period.
  void recordRateLimit() {
    _cooldownUntil = DateTime.now().add(_cooldownDuration);
  }

  /// Clear the cooldown (e.g. after a successful email operation).
  void clearCooldown() {
    _cooldownUntil = null;
  }
}

/// Notifier that wraps Supabase Auth and keeps local state in sync.
///
/// Listens to Supabase auth state changes and keeps [AuthState] in sync.
/// Starts in [AuthState.loading] until the initial session check completes.
class AuthNotifier extends Notifier<AuthState> {
  SupabaseAuthService get _service => SupabaseAuthService.instance;

  // ignore: unused_field
  StreamSubscription<dynamic>? _authSubscription;

  @override
  AuthState build() {
    // Return loading state immediately; async init runs below
    _initialize();
    return const AuthState.loading();
  }

  Future<void> _initialize() async {
    // Listen to Supabase auth state changes for the lifetime of this notifier
    _authSubscription = _service.authStateChanges.listen((event) async {
      final session = event.session;
      final user = session?.user;

      if (user == null) {
        // Signed out
        state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          user: null,
          profile: null,
          role: null,
        );
        return;
      }

      // Signed in — load profile from profiles table
      final profile = await _service.getProfile(user.id);
      final role =
          profile != null ? UserRole.fromString(profile.role) : UserRole.admin;

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        profile: profile,
        role: role,
      );
    });

    // Perform initial session check
    final session = _service.currentSession;
    final user = session?.user;

    if (user == null) {
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        user: null,
        profile: null,
        role: null,
      );
      return;
    }

    // Load profile for existing session
    final profile = await _service.getProfile(user.id);
    final role =
        profile != null ? UserRole.fromString(profile.role) : UserRole.admin;

    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      user: user,
      profile: profile,
      role: role,
    );
  }

  /// Sign up with email + password. Creates auth user + profiles row.
  ///
  /// Checks the email rate limiter before calling Supabase. If rate-limited,
  /// throws an [AuthException] with a clear message telling the user to wait.
  /// Returns the [AuthResponse] so callers can check email confirmation status.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? orgName,
    String? phone,
  }) async {
    // Check rate limiter before attempting Supabase call
    final limiter = EmailRateLimiter.instance;
    if (limiter.isRateLimited) {
      throw AuthException(
        'Email rate limit exceeded. Please wait ${limiter.secondsRemaining} '
        'seconds and try again.',
      );
    }

    try {
      final response = await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        orgName: orgName,
        phone: phone,
      );

      // Clear any cooldown on successful email operation
      limiter.clearCooldown();

      return response;
    } on AuthException catch (e) {
      // If it's a rate limit error, record the cooldown
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('signup emails disabled')) {
        limiter.recordRateLimit();
      }
      rethrow;
    }
  }

  /// Sign in with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _service.signIn(email: email, password: password);
  }

  /// Send a password reset email to the given address.
  ///
  /// Checks the email rate limiter before calling Supabase.
  Future<void> resetPassword(String email) async {
    final limiter = EmailRateLimiter.instance;
    if (limiter.isRateLimited) {
      throw AuthException(
        'Email rate limit exceeded. Please wait ${limiter.secondsRemaining} '
        'seconds and try again.',
      );
    }

    try {
      await _service.resetPassword(email);
      limiter.clearCooldown();
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        limiter.recordRateLimit();
      }
      rethrow;
    }
  }

  /// Resend email confirmation (uses password reset flow).
  ///
  /// Checks the email rate limiter before calling Supabase.
  Future<void> resendConfirmationEmail(String email) async {
    final limiter = EmailRateLimiter.instance;
    if (limiter.isRateLimited) {
      throw AuthException(
        'Email rate limit exceeded. Please wait ${limiter.secondsRemaining} '
        'seconds and try again.',
      );
    }

    try {
      await _service.resendConfirmationEmail(email);
      limiter.clearCooldown();
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        limiter.recordRateLimit();
      }
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _service.signOut();
  }
}

/// Riverpod provider for Supabase-backed authentication.
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);