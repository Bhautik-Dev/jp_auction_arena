import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Forgot password')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Password help',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Password reset is not available for local demo accounts. '
                'Select a documented demo account on the login screen.',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_message!),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Continue',
                onPressed: () => setState(
                  () => _message =
                      'No reset email was sent. Demo authentication is '
                      'local only.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Back to login',
                onPressed: () => context.go(RouteAccessPolicy.login),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
