import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });

    final ok = await context.read<AuthProvider>().unlock();
    if (!mounted) return;

    setState(() {
      _busy = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().session?.user;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(user: user, size: 64),
                const SizedBox(height: Insets.lg),
                Text(
                  user == null
                      ? 'Locked'
                      : 'Welcome back, ${user.name.split(' ').first}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  'Unlock to return to your workspace.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_failed) ...[
                  const SizedBox(height: Insets.lg),
                  Text(
                    'Unlock failed or was cancelled.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.xxl),
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _unlock,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(_busy ? 'Waiting…' : 'Unlock'),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  child: const Text('Sign out instead'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
