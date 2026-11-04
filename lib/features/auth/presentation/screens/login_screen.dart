import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';
import 'package:jp_auction_arena/core/theme/app_spacing.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/application/route_access_policy.dart';
import 'package:jp_auction_arena/features/auth/domain/models/app_role.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('login'),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.sports_cricket,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) =>
                        (value ?? '').isEmpty ? 'Enter your password' : null,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(RouteAccessPolicy.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      key: const Key('login-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: _submitting ? 'Signing in...' : 'Login',
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _DemoAccountList(
                    onSelected: (email, password) {
                      setState(() {
                        _emailController.text = email;
                        _passwordController.text = password;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    await ref
        .read(authSessionProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
    if (!mounted) return;
    final authState = ref.read(authSessionProvider);
    setState(() {
      _submitting = false;
      _errorMessage = authState.hasError ? authState.error.toString() : null;
    });
    if (authState.hasValue && authState.value != null) {
      context.go(RouteAccessPolicy.landingFor(authState.value!.user.role));
    }
  }
}

class _DemoAccountList extends StatelessWidget {
  const _DemoAccountList({required this.onSelected});

  final void Function(String email, String password) onSelected;

  static const _accounts = [
    ('Super Admin', 'admin@demo.jp', 'DemoAdmin!2026', AppRole.superAdmin),
    (
      'Tournament Admin / Operator',
      'operator@demo.jp',
      'DemoOperator!2026',
      AppRole.tournamentAdmin,
    ),
    (
      'Team Owner / Manager',
      'team@demo.jp',
      'DemoTeam!2026',
      AppRole.teamManager,
    ),
    (
      'Public Viewer',
      'viewer@demo.jp',
      'DemoViewer!2026',
      AppRole.publicViewer,
    ),
  ];

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Development demo accounts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Local-only examples. Not real accounts and not production '
            'authentication.',
          ),
          for (final account in _accounts)
            TextButton(
              onPressed: () => onSelected(account.$2, account.$3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${account.$1} - ${account.$2}'),
              ),
            ),
        ],
      ),
    ),
  );
}
