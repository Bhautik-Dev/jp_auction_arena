import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/auth_provider.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authProvider);

    return FeaturePlaceholderScreen(
      title: 'Auctioneer Security & Access',
      description: 'Supabase Auth session and device access controls',
      icon: Icons.lock_outline_rounded,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: authState.isAuthenticated
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                    ),
                    child: Icon(
                      authState.isAuthenticated
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      size: 44,
                      color: authState.isAuthenticated
                          ? AppColors.success
                          : AppColors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authState.isAuthenticated
                        ? 'Session Active'
                        : 'Not Signed In',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authState.isAuthenticated
                        ? 'Signed in as ${authState.email.isNotEmpty ? authState.email : 'user'} (${authState.role?.displayName ?? 'User'})'
                        : 'Sign in to access auction controls on this device.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (authState.isAuthenticated) ...[
                    GradientButton(
                      onPressed: _isLoading ? null : _handleLogout,
                      isLoading: _isLoading,
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentPink,
                        side: const BorderSide(color: AppColors.accentPink),
                      ),
                      child: const Text('Change Account'),
                    ),
                  ] else ...[
                    GradientButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      isLoading: _isLoading,
                      icon: Icons.login_rounded,
                      label: 'Sign In',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
