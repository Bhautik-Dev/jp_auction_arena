import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/auth_provider.dart';
import '../auth/reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _cooldownTimer;

  // Sign in controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Sign up controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpOrgController = TextEditingController();
  final _signUpPhoneController = TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpOrgController.dispose();
    _signUpPhoneController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _signInEmailController.text.trim(),
            password: _signInPasswordController.text.trim(),
          );

      if (mounted) {
        setState(() => _isLoading = false);
        context.go(RouteNames.dashboardPath);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign in failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    // Proactive rate-limit check
    if (_isRateLimited) {
      setState(() {
        _errorMessage = 'Too many sign-up attempts. '
            'Please wait ${_getCooldownSeconds()} seconds and try again.';
        _startCooldownTimer();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(authProvider.notifier).signUp(
            email: _signUpEmailController.text.trim(),
            password: _signUpPasswordController.text.trim(),
            fullName: _signUpNameController.text.trim(),
            orgName: _signUpOrgController.text.trim().isEmpty
                ? null
                : _signUpOrgController.text.trim(),
            phone: _signUpPhoneController.text.trim().isEmpty
                ? null
                : _signUpPhoneController.text.trim(),
          );

      if (!mounted) return;

      // Stop loading indicator regardless of outcome
      setState(() => _isLoading = false);

      // Check if email confirmation is required
      final needsConfirmation = response.user != null &&
          response.user!.emailConfirmedAt == null;

      if (needsConfirmation) {
        // Email confirmation required — show guidance and switch to sign-in
        setState(() => _isSignUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created! Please check your email to confirm your account, then sign in.',
            ),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Resend',
              onPressed: () async {
                await ref
                    .read(authProvider.notifier)
                    .resendConfirmationEmail(
                      _signUpEmailController.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Confirmation email resent.'),
                      backgroundColor: AppColors.info,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),
        );
        return;
      }

      // No confirmation required — auto-sign in and go to dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      context.go(RouteNames.dashboardPath);
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign up failed: $e';
        _isLoading = false;
      });
    }
  }

  String _mapAuthError(String? message) {
    final msg = (message ?? '').toLowerCase();

    // Email rate limit — Supabase server-side protection
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('signup emails disabled') ||
        msg.contains('rate_limit')) {
      final remaining = _getCooldownSeconds();
      if (remaining > 0) {
        return 'Too many sign-up attempts. Please wait $remaining seconds and try again.';
      }
      return 'Too many sign-up attempts. Please wait a few minutes and try again.';
    }

    // Invalid credentials / wrong password / email not confirmed
    if (msg.contains('invalid login') ||
        msg.contains('wrong password') ||
        msg.contains('email not confirmed')) {
      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email address before signing in. Check your inbox (and spam folder) for the confirmation link.';
      }
      return 'Invalid email or password. Please try again.';
    }

    // Already registered
    if (msg.contains('already registered') || msg.contains('user already exists')) {
      return 'An account with this email already exists. Try signing in.';
    }

    // Network errors
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Password too short
    if (msg.contains('password should be at least')) {
      return 'Password is too short. Please use at least 6 characters.';
    }

    return message ?? 'Authentication failed. Please try again.';
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  /// Returns remaining cooldown seconds, or 0 if not rate-limited.
  int _getCooldownSeconds() {
    return EmailRateLimiter.instance.secondsRemaining;
  }

  /// Whether email operations are currently rate-limited.
  bool get _isRateLimited => EmailRateLimiter.instance.isRateLimited;

  /// Start a countdown timer that updates the UI each second while rate-limited.
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _cooldownTimer?.cancel();
        return;
      }
      if (!EmailRateLimiter.instance.isRateLimited) {
        _cooldownTimer?.cancel();
        return;
      }
      setState(() {}); // rebuild to update countdown
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // If already authenticated, redirect to dashboard instead of showing spinner
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RouteNames.dashboardPath);
      });
      return const SizedBox.shrink();
    }

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
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderColor: AppColors.cardBorder,
                  hasGlow: true,
                  child: _isSignUp ? _buildSignUpCard() : _buildSignInCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                shaderCallback: (bounds) =>
                    AppColors.buttonGradient.createShader(
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
                'Sign in to your auction account',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: _clearError,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sign in form
        Form(
          key: _signInFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _signInEmailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'you@club.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.primaryBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signInPasswordController,
                obscureText: true,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outlined,
                      color: AppColors.primaryBlue),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSignIn(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.accentPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: _isLoading ? null : _handleSignIn,
                isLoading: _isLoading,
                icon: Icons.login_rounded,
                label: 'Sign In',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isSignUp = true);
                          },
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        color: AppColors.accentPink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpCard() {
    return Column(
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
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.buttonGradient.createShader(
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
                'Create your auctioneer account',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: _clearError,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Rate-limit cooldown warning
        if (_isRateLimited) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email rate limit reached. Please wait ${_getCooldownSeconds()} seconds before creating another account.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sign up form
        Form(
          key: _signUpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _signUpNameController,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Jayesh Patel',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.primaryBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signUpEmailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'you@club.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppColors.primaryBlue),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signUpPasswordController,
                obscureText: true,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  hintText: '•••••••• (min 6 chars)',
                  prefixIcon: Icon(Icons.lock_outlined,
                      color: AppColors.primaryBlue),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSignUp(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signUpOrgController,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Organization / Club',
                  hintText: 'e.g. Gujarat Premier Cricket Club',
                  prefixIcon: Icon(Icons.business_rounded,
                      color: AppColors.secondaryPurple),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signUpPhoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _clearError(),
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  hintText: '+91 98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppColors.accentPink),
                ),
              ),
              const SizedBox(height: 26),
              GradientButton(
                onPressed: _isLoading ? null : _handleSignUp,
                isLoading: _isLoading,
                icon: Icons.person_add_rounded,
                label: 'Create Account',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isSignUp = false);
                          },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: AppColors.accentPink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
