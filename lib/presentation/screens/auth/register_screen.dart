import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await context.read<AuthProvider>().register(
      RegistrationDraft(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        organizationName: _org.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final failure = auth.failure;
    final fieldErrors = failure is ValidationFailure
        ? failure.fieldErrors
        : const <String, String>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 460,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(size: 40),
                  const SizedBox(height: Insets.lg),
                  Text(
                    'Start a workspace',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    'You will be the admin of the organization you create here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Insets.xl),

                  if (failure != null && failure is! ValidationFailure)
                    FormErrorBanner(message: failure.message),

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: Validators.name,
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _org,
                    decoration: InputDecoration(
                      labelText: 'Organization name',
                      prefixIcon: const Icon(Icons.apartment_rounded),
                      errorText: fieldErrors['organization'],
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.required(value, field: 'Organization name'),
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: 'Work email',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      errorText: fieldErrors['email'],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    validator: Validators.email,
                    onChanged: (_) => auth.clearFailure(),
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText:
                          'At least 8 characters, with a letter and a number',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    validator: Validators.newPassword,
                  ),
                  const SizedBox(height: Insets.lg),

                  TextFormField(
                    controller: _confirm,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    obscureText: _obscure,
                    validator: (value) =>
                        Validators.confirmPassword(value, _password.text),
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
                        : const Text('Create account'),
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
