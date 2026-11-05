import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/feature_placeholder_screen.dart';

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  final _pinController = TextEditingController();
  bool _unlocked = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final savedPin = settingsAsync.value?.pin ?? '1234';

    return FeaturePlaceholderScreen(
      title: 'Auctioneer Security & Access',
      description: 'PIN protection and role-based device access controls',
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
                      color: _unlocked ? AppColors.success.withValues(alpha: 0.15) : AppColors.surfaceLight,
                    ),
                    child: Icon(
                      _unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 44,
                      color: _unlocked ? AppColors.success : AppColors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _unlocked ? 'Admin Mode Unlocked' : 'Enter Auctioneer PIN',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _unlocked
                        ? 'Master admin controls are verified for this device.'
                        : 'Default security PIN is $savedPin. Change it anytime in Settings.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (!_unlocked) ...[
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 10, fontSize: 24, fontWeight: FontWeight.bold),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: '••••',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      onPressed: () {
                        if (_pinController.text.trim() == savedPin) {
                          setState(() => _unlocked = true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid PIN. Please try again.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      label: 'Verify & Authorize',
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _unlocked = false;
                          _pinController.clear();
                        });
                      },
                      child: const Text('Lock Device'),
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
