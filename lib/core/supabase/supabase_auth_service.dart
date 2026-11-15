import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jp_auction_arena/core/supabase/supabase_client.dart';
import 'package:jp_auction_arena/core/supabase/supabase_models.dart';
import 'package:jp_auction_arena/core/utils/app_logger.dart';

/// Wraps Supabase Auth operations for JP AUCTION ARENA.
///
/// Handles email/password sign up, sign in, password reset, sign out,
/// and profile row creation in the `profiles` table.
class SupabaseAuthService {
  SupabaseAuthService._();

  static final SupabaseAuthService _instance = SupabaseAuthService._();

  /// Singleton accessor.
  static SupabaseAuthService get instance => _instance;

  SupabaseClient? get _client => SupabaseClientService.instance.client;

  /// Whether Supabase client is initialized.
  bool get isInitialized => _client != null;

  /// Current authenticated user, or null if none.
  User? get currentUser => _client?.auth.currentUser;

  /// Current session, or null if none.
  Session? get currentSession => _client?.auth.currentSession;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client?.auth.onAuthStateChange ??
      const Stream.empty();

  /// Sign up with email + password. Creates auth user + profiles row.
  ///
  /// If email confirmation is disabled in Supabase Auth settings, the user
  /// is signed in immediately and can proceed to the dashboard.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? orgName,
    String? phone,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }

    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'org_name': orgName?.trim(),
        'phone': phone?.trim(),
        'role': 'admin',
      },
    );

    // Create/update profiles row if user was created.
    if (response.user != null) {
      await _upsertProfile(
        id: response.user!.id,
        email: email.trim(),
        fullName: fullName.trim(),
        orgName: orgName?.trim(),
        phone: phone?.trim(),
        role: 'admin',
      );
    }

    return response;
  }

  /// Sign in with email + password.
  ///
  /// Works with both confirmed and unconfirmed users when email confirmation
  /// is disabled in Supabase Auth settings. When confirmation is required,
  /// unconfirmed users receive an "email not confirmed" error.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    await client.auth.signOut();
  }

  /// Send a password reset email to the given address.
  ///
  /// This is the standard Supabase flow for password recovery. It is also
  /// used as the mechanism to re-establish contact with unconfirmed users
  /// when custom SMTP is configured.
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Resend a confirmation/re-establishment email.
  ///
  /// Supabase's client SDK does not expose a dedicated "resend confirmation"
  /// endpoint. This method uses [resetPasswordForEmail] which sends a
  /// password-reset email — the recommended Supabase approach for contacting
  /// an unconfirmed user.
  Future<void> resendConfirmationEmail(String email) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Check whether the current session's user has confirmed their email.
  bool get isEmailConfirmed {
    final user = currentUser;
    if (user == null) return false;
    return user.emailConfirmedAt != null;
  }

  /// Check whether email confirmation is likely required based on the last
  /// known auth state. Returns true if no session exists or the current
  /// user's email is unconfirmed.
  Future<bool> isConfirmationRequired() async {
    final user = currentUser;
    if (user == null) return false;
    return user.emailConfirmedAt == null;
  }

  /// Upsert a row into the `profiles` table.
  Future<void> _upsertProfile({
    required String id,
    required String email,
    required String fullName,
    String? orgName,
    String? phone,
    String? role,
  }) async {
    final client = _client;
    if (client == null) return;

    await client.from('profiles').upsert({
      'id': id,
      'email': email,
      'full_name': fullName,
      'org_name': orgName,
      'phone': phone,
      'role': role ?? 'admin',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch a profile row by user id.
  Future<SupabaseProfile?> getProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return SupabaseProfile.fromJson(data);
    } catch (e) {
      AppLogger.warning('Profile not found for user $userId: $e',
          tag: 'SupabaseAuth');
      return null;
    }
  }

  /// Call the `add_auction_member` RPC to add an operator to an auction.
  Future<Map<String, dynamic>> addAuctionMember({
    required String auctionId,
    required String email,
    String role = 'operator',
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }

    final result = await client.rpc('add_auction_member', params: {
      'auction_id': auctionId,
      'email': email,
      'role': role,
    });

    return result;
  }

  /// Call the `remove_auction_member` RPC to remove an operator from an auction.
  Future<Map<String, dynamic>> removeAuctionMember({
    required String auctionId,
    required String email,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }

    final result = await client.rpc('remove_auction_member', params: {
      'auction_id': auctionId,
      'email': email,
    });

    return result;
  }

  /// Fetch auction members (profiles joined via auction_members) for an auction.
  Future<List<SupabaseProfile>> getAuctionMembers(String auctionId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final data = await client
          .from('auction_members')
          .select('''
            profile_id,
            profiles (
              id, email, full_name, org_name, phone, role, created_at, updated_at
            )
          ''')
          .eq('auction_id', auctionId);

      final List<dynamic> rows = data;
      return rows
          .map((row) {
            final profile = row['profiles'];
            if (profile == null) return null;
            return SupabaseProfile.fromJson(
              Map<String, dynamic>.from(profile as Map),
            );
          })
          .whereType<SupabaseProfile>()
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to load auction members: $e',
          tag: 'SupabaseAuth');
      return [];
    }
  }
}