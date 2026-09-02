import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/entities/auth_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/responsive.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MemberProvider>().loadOrganizationIfNeeded(),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Sign out?',
      message:
          'Your tokens and any cached project data on this device will be cleared.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final organization = context.watch<MemberProvider>().organization;
    final session = auth.session;
    final user = session?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Row(
                  children: [
                    UserAvatar(user: user, size: 56),
                    const SizedBox(width: Insets.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Signed out',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: Insets.sm),
                          Wrap(
                            spacing: Insets.sm,
                            children: [
                              if (organization != null)
                                Chip(
                                  label: Text(organization.name),
                                  visualDensity: VisualDensity.compact,
                                ),
                              if (session != null)
                                Chip(
                                  label: Text(session.role.label),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            if (session != null) _SessionCard(session: session),
            const SizedBox(height: Insets.lg),

            const SectionHeader(title: 'Appearance'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      settings.setThemeMode(selection.first),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            const SectionHeader(title: 'Security'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: auth.biometricLockEnabled,
                    onChanged: auth.biometricAvailable
                        ? auth.setBiometricLock
                        : null,
                    title: const Text('Biometric unlock'),
                    subtitle: Text(
                      auth.biometricAvailable
                          ? 'Ask for a fingerprint or face scan when the app returns from the background.'
                          : 'No biometric hardware enrolled on this device.',
                    ),
                    secondary: const Icon(Icons.fingerprint_rounded),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.timer_outlined),
                    title: Text('Automatic sign-out'),
                    subtitle: Text('After 10 minutes without any interaction.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),

            const SectionHeader(title: 'Testing'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Developer options'),
                subtitle: const Text(
                  'Offline mode, simulated failures and mock data reset',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.developer),
              ),
            ),
            const SizedBox(height: Insets.xl),

            OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  const _SessionCard({required this.session});

  final AuthSession session;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  Timer? _ticker;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final ok = await context.read<AuthProvider>().refreshTokenNow();
    if (!mounted) return;

    setState(() => _refreshing = false);
    if (ok) {
      AppFeedback.success(context, 'New access token issued');
    } else {
      AppFeedback.info(context, 'Could not refresh the session');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.session.accessTokenTimeLeft();
    final expired = remaining == Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  expired ? Icons.lock_clock_rounded : Icons.vpn_key_outlined,
                  size: 18,
                  color: expired
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: Insets.sm),
                Text('Session', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: Insets.md),
            Text(
              expired
                  ? 'Access token expired — the next request will refresh it automatically.'
                  : 'Access token expires in ${_format(remaining)}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Insets.xs),
            Text(
              'Refresh token valid until '
              '${Dates.formatTimestamp(widget.session.refreshTokenExpiresAt)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.md),
            OutlinedButton.icon(
              onPressed: _refreshing ? null : _refresh,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: _refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Refresh token now'),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
