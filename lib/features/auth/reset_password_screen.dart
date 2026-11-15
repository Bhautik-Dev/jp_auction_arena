import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(email);

      if (mounted) {
        setState(() {
          _sent = true;
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Reset failed: $e';
        _isLoading = false;
      });
    }
  }

  String _mapAuthError(String? message) {
    final msg = (message ?? '').toLowerCase();
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Network error. Please check your connection and try again.';
    }
    return message ?? 'Password reset failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderColor: AppColors.cardBorder,
                  hasGlow: true,
                  child: _sent ? _buildSentCard() : _buildResetCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              Icons.email_outlined,
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
        const SizedBox(height: 8),
        const Text(
          'Reset Your Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email and we’ll send a reset link',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
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

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _clearError(),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'you@club.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue),
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
          onFieldSubmitted: (_) => _handleReset(),
        ),
        const SizedBox(height: 24),

        GradientButton(
          onPressed: _isLoading ? null : _handleReset,
          isLoading: _isLoading,
          icon: Icons.email_rounded,
          label: 'Send Reset Link',
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Remember your password? ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => context.go(RouteNames.loginPath),
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
    );
  }

  Widget _buildSentCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Reset Link Sent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Check your email inbox (and spam folder) for a password reset link.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GradientButton(
          onPressed: () => context.go(RouteNames.loginPath),
          icon: Icons.login_rounded,
          label: 'Go to Sign In',
        ),
      ],
    );
  }
}
