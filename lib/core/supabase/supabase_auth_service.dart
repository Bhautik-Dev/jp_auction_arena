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

    // If email confirmation is not required, user is signed in immediately.
    // Create/update profiles row.
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
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    await client.auth.resetPasswordForEmail(email.trim());
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