import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // First Launch - Profile Creation Form
  final _createFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _phoneController = TextEditingController();
  final _createPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  UserRole _selectedRole = UserRole.admin;

  // Returning User - PIN entry
  final _pinController = TextEditingController();
  UserRole _loginRole = UserRole.admin;
  String? _pinErrorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _phoneController.dispose();
    _createPinController.dispose();
    _confirmPinController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (!_createFormKey.currentState!.validate()) return;

    if (_createPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Please re-enter.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).createProfile(
          name: _nameController.text,
          orgName: _orgController.text,
          phone: _phoneController.text,
          pin: _createPinController.text,
          role: _selectedRole,
        );

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${_nameController.text}! Profile initialized.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RouteNames.dashboardPath);
    }
  }

  void _handlePinLogin() {
    setState(() {
      _pinErrorMessage = null;
    });

    final enteredPin = _pinController.text.trim();
    if (enteredPin.length != 4) {
      setState(() {
        _pinErrorMessage = 'Please enter your 4-digit PIN';
      });
      return;
    }

    final success = ref.read(authProvider.notifier).loginWithPin(
          enteredPin,
          selectedRole: _loginRole,
        );

    if (success) {
      context.go(RouteNames.dashboardPath);
    } else {
      setState(() {
        _pinErrorMessage = 'Incorrect PIN. Try again or reset.';
        _pinController.clear();
      });
    }
  }

  Future<void> _showForgotPinDialog() async {
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Text(
                'Reset & Wipe Local Data',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Because JP AUCTION ARENA is strictly offline with NO cloud servers, forgotten PINs cannot be recovered through email/SMS.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'WARNING: Resetting will permanently delete all tournaments, teams, players, bids, and settings on this device!',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type "RESET" below to confirm complete local wipe:',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'RESET',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (confirmController.text.trim().toUpperCase() == 'RESET') {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please type "RESET" in all capitals.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Wipe All & Reset'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await ref.read(authProvider.notifier).wipeAllDataAndReset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local data wiped. Create a new profile.'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isFirstLaunch = !authState.isProfileCreated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient lights
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryPurple.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isFirstLaunch ? 580 : 440,
                ),
                child: isFirstLaunch
                    ? _buildFirstLaunchProfileCard()
                    : _buildReturningUserPinCard(authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. First Launch Profile Creation Card
  Widget _buildFirstLaunchProfileCard() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderColor: AppColors.cardBorder,
      hasGlow: true,
      child: Form(
        key: _createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_cricket_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.buttonGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'JP AUCTION ARENA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Welcome! Setup your master auction profile',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Auctioneer / Admin Name *',
                hintText: 'e.g. Jayesh Patel',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),

            // Organization
            TextFormField(
              controller: _orgController,
              decoration: const InputDecoration(
                labelText: 'Organization / Club / League *',
                hintText: 'e.g. Gujarat Premier Cricket Club',
                prefixIcon: Icon(Icons.business_rounded, color: AppColors.secondaryPurple),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter organization name' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number',
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accentPink),
              ),
            ),
            const SizedBox(height: 20),

            // Role Selector
            const Text(
              'Select Primary Role:',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildRoleRadioGroup(
              selected: _selectedRole,
              onChanged: (r) => setState(() => _selectedRole = r),
            ),
            const SizedBox(height: 20),

            // PIN & Confirm PIN
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _createPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 6, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Set 4-Digit PIN *',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.gold),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 4) {
                        return '4 digits required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 6, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN *',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.gold),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 4) {
                        return '4 digits required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Create button
            GradientButton(
              onPressed: _isLoading ? null : _handleCreateProfile,
              isLoading: _isLoading,
              icon: Icons.check_circle_outline_rounded,
              label: 'Create Profile & Enter Arena',
            ),

            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Text(
                    'Stored safely in local Hive offline database',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Returning User PIN Login Card
  Widget _buildReturningUserPinCard(AuthState authState) {
    final profile = authState.settings;

    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderColor: AppColors.cardBorder,
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo & Organization badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.gavel_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            profile.profileName.isNotEmpty ? profile.profileName : 'JP AUCTION ARENA',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.orgName.isNotEmpty ? profile.orgName : 'Cricket Auction Management',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Role Switcher for session
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Access As: ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                DropdownButton<UserRole>(
                  value: _loginRole,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.card,
                  isDense: true,
                  style: const TextStyle(
                    color: AppColors.accentPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (role) {
                    if (role != null) {
                      setState(() => _loginRole = role);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Enter 4-Digit Security PIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 4-Digit PIN input
          SizedBox(
            width: 240,
            child: TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                letterSpacing: 16,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                errorText: _pinErrorMessage,
                prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primaryBlue),
              ),
              onSubmitted: (_) => _handlePinLogin(),
            ),
          ),
          const SizedBox(height: 22),

          // Unlock Arena Button
          GradientButton(
            onPressed: _handlePinLogin,
            icon: Icons.lock_open_rounded,
            label: 'Unlock Arena',
          ),
          const SizedBox(height: 18),

          // Forgot PIN -> Reset by wiping data
          TextButton.icon(
            onPressed: _showForgotPinDialog,
            icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textSecondary),
            label: const Text(
              'Forgot PIN? Reset App Data',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRadioGroup({
    required UserRole selected,
    required ValueChanged<UserRole> onChanged,
  }) {
    return Column(
      children: UserRole.values.map((role) {
        final isSelected = selected == role;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(role),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accentPink : AppColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.accentPink : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          role.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
