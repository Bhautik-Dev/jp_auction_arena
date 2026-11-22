import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_card.dart';

class OperatorsScreen extends StatelessWidget {
  const OperatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operators'),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.supervised_user_circle_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 20),
              const Text(
                'Operator Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Authentication has been removed. '
                'All users have full access to all auction controls.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
