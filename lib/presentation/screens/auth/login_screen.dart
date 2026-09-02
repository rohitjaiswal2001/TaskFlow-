import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/responsive.dart';
import '../../widgets/user_avatar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSignOutNotice());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showSignOutNotice() {
    final auth = context.read<AuthProvider>();
    final reason = auth.lastSignOutReason;
    if (reason == null || reason == SignOutReason.manual) return;

    final message = switch (reason) {
      SignOutReason.inactivity => 'Signed out after a period of inactivity.',
      SignOutReason.sessionExpired =>
        'Your session expired. Please sign in again.',
      SignOutReason.manual => '',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    auth.clearSignOutReason();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await context.read<AuthProvider>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !ok) return;
    _passwordController.clear();
  }

  Future<void> _pickDemoAccount() async {
    final auth = context.read<AuthProvider>();

    final chosen = await showModalBottomSheet<DemoCredential>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DemoAccountsSheet(credentials: auth.demoCredentials),
    );

    if (chosen == null || !mounted) return;

    _emailController.text = chosen.email;
    _passwordController.text = chosen.password;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final failure = auth.failure;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 460,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Insets.xl,
              Insets.xxl,
              Insets.xl,
              Insets.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(),
                  const SizedBox(height: Insets.xl),
                  Text('Welcome back', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: Insets.sm),
                  Text(
                    'Sign in to pick up where your team left off.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Insets.xxl),

                  if (failure != null && failure is! ValidationFailure)
                    FormErrorBanner(message: failure.message),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Work email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    autocorrect: false,
                    validator: Validators.email,
                    onChanged: (_) => auth.clearFailure(),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onChanged: (_) => auth.clearFailure(),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Insets.xl),

                  FilledButton(
                    onPressed: auth.isSubmitting ? null : _submit,
                    child: auth.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: Insets.md),

                  OutlinedButton.icon(
                    onPressed: auth.isSubmitting || auth.demoCredentials.isEmpty
                        ? null
                        : _pickDemoAccount,
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Use a demo account'),
                  ),
                  const SizedBox(height: Insets.xl),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'New here?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(Routes.register),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountsSheet extends StatelessWidget {
  const _DemoAccountsSheet({required this.credentials});

  final List<DemoCredential> credentials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demo accounts', style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.xs),
            Text(
              'Two organizations, an admin and a member in each. '
              'Admin-only actions are blocked for members.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.lg),
            for (final credential in credentials)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const UserAvatar.unassigned(),
                title: Text(credential.orgName),
                subtitle: Text(
                  '${credential.roleLabel} · ${credential.email}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onTap: () => Navigator.of(context).pop(credential),
              ),
          ],
        ),
      ),
    );
  }
}
