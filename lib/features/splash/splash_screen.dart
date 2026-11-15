import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../data/repositories/auth_provider.dart';
import 'widgets/cricket_bat_ball_animation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  // Minimum splash duration so the animation is visible (prevents flash)
  static const Duration _minSplashDuration = Duration(milliseconds: 1800);

  bool _navigated = false;
  Timer? _minDurationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    // Enforce a minimum splash duration so the animation is visible
    _minDurationTimer = Timer(_minSplashDuration, () {
      _tryNavigate();
    });
  }

  /// Called when auth state is ready (isLoading == false).
  /// Navigates to Dashboard if signed in, otherwise Login.
  void _tryNavigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final authState = ref.read(authProvider);
    if (!authState.isLoading) {
      if (authState.isAuthenticated) {
        context.go(RouteNames.dashboardPath);
      } else {
        context.go(RouteNames.loginPath);
      }
    }
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auth state may have changed reactively — try to navigate
    _tryNavigate();
  }

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state so we react when it settles
    final authState = ref.watch(authProvider);

    // Once auth is no longer loading, navigate (safety net)
    if (!authState.isLoading && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_navigated) {
          _navigated = true;
          if (authState.isAuthenticated) {
            context.go(RouteNames.dashboardPath);
          } else {
            context.go(RouteNames.loginPath);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient gradient orbs
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPink.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated Bat and Leather Ball
                        const CricketBatBallAnimation(size: 190),
                        const SizedBox(height: 32),

                        // Animated Title in blue -> purple -> pink gradient
                        AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: child,
                            );
                          },
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return AppColors.buttonGradient.createShader(
                                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                  );
                                },
                                blendMode: BlendMode.srcIn,
                                child: const Text(
                                  'JP AUCTION ARENA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Text(
                                  'CRICKET PLAYER AUCTION MANAGER',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Loading progress pill
                        SizedBox(
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentPink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Starting local offline database...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Version & Offline tag
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 4, backgroundColor: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '100% Offline • Hive Storage • Multiplatform',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
