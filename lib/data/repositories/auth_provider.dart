import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';
import 'settings_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isProfileCreated;
  final UserRole currentRole;
  final AppSettings settings;

  const AuthState({
    required this.isAuthenticated,
    required this.isProfileCreated,
    required this.currentRole,
    required this.settings,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isProfileCreated,
    UserRole? currentRole,
    AppSettings? settings,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isProfileCreated: isProfileCreated ?? this.isProfileCreated,
      currentRole: currentRole ?? this.currentRole,
      settings: settings ?? this.settings,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);

  @override
  AuthState build() {
    final settings = _settingsRepo.getSettings();
    final hasProfile = settings.isSetupComplete && settings.pin.isNotEmpty;
    return AuthState(
      isAuthenticated: false,
      isProfileCreated: hasProfile,
      currentRole: settings.role,
      settings: settings,
    );
  }

  /// Check if the user needs to register or enter PIN
  void refresh() {
    final settings = _settingsRepo.getSettings();
    final hasProfile = settings.isSetupComplete && settings.pin.isNotEmpty;
    state = state.copyWith(
      isProfileCreated: hasProfile,
      currentRole: settings.role,
      settings: settings,
    );
  }

  /// Create local profile on first launch
  Future<bool> createProfile({
    required String name,
    required String orgName,
    required String phone,
    required String pin,
    required UserRole role,
  }) async {
    final newSettings = state.settings.copyWith(
      profileName: name.trim(),
      orgName: orgName.trim(),
      phone: phone.trim(),
      pin: pin.trim(),
      isSetupComplete: true,
      role: role,
    );
    await _settingsRepo.saveSettings(newSettings);
    state = AuthState(
      isAuthenticated: true,
      isProfileCreated: true,
      currentRole: role,
      settings: newSettings,
    );
    return true;
  }

  /// Login with 4-digit PIN
  bool loginWithPin(String pin, {UserRole? selectedRole}) {
    final currentPin = state.settings.pin;
    if (currentPin.isEmpty) {
      return false;
    }

    if (pin.trim() == currentPin.trim()) {
      final effectiveRole = selectedRole ?? state.settings.role;
      state = state.copyWith(
        isAuthenticated: true,
        currentRole: effectiveRole,
      );
      return true;
    }
    return false;
  }

  /// Switch role on the fly (for testing or multi-role sessions)
  Future<void> switchRole(UserRole role) async {
    final updated = state.settings.copyWith(role: role);
    await _settingsRepo.saveSettings(updated);
    state = state.copyWith(
      currentRole: role,
      settings: updated,
    );
  }

  /// Logout
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  /// Forgot PIN: Wipe all local data from all Hive boxes and reset
  Future<void> wipeAllDataAndReset() async {
    final auctionsBox = Hive.box<Auction>(HiveBoxes.auctions);
    final teamsBox = Hive.box<Team>(HiveBoxes.teams);
    final playersBox = Hive.box<Player>(HiveBoxes.players);
    final bidsBox = Hive.box<Bid>(HiveBoxes.bids);
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.settings);

    await auctionsBox.clear();
    await teamsBox.clear();
    await playersBox.clear();
    await bidsBox.clear();
    await settingsBox.clear();

    final blankSettings = AppSettings(
      profileName: '',
      orgName: '',
      phone: '',
      pin: '',
      isSetupComplete: false,
      role: UserRole.admin,
    );
    await _settingsRepo.saveSettings(blankSettings);

    state = AuthState(
      isAuthenticated: false,
      isProfileCreated: false,
      currentRole: UserRole.admin,
      settings: blankSettings,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
