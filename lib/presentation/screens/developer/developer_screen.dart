import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/service_locator.dart';
import '../../../core/config/simulation_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/datasources/local/cache_store.dart';
import '../../../data/datasources/mock/mock_database.dart';
import '../../../data/datasources/mock/network_simulator.dart';
import '../../providers/member_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/project_list_provider.dart';
import '../../providers/task_list_provider.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/responsive.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  Future<void> _reloadEverything(BuildContext context) async {
    await Future.wait([
      context.read<ProjectListProvider>().refresh(),
      context.read<TaskListProvider>().refresh(),
      context.read<MemberProvider>().refresh(),
      context.read<NotificationProvider>().refresh(),
    ]);
  }

  Future<void> _resetMockData(BuildContext context) async {
    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Reset mock data?',
      message:
          'Projects, tasks, comments and notifications go back to what the '
          'bundled JSON asset contains. Anything created in the app is lost.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;

    await locator<MockDatabase>().reset();
    await locator<CacheStore>().clearAll();
    if (!context.mounted) return;

    await _reloadEverything(context);
    if (!context.mounted) return;
    AppFeedback.success(context, 'Mock data reset');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SimulationSettings>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Developer options')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            Text(
              'The app talks to a simulated backend. These switches make it '
              'misbehave on purpose so the loading, offline and error states '
              'can be demonstrated.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.lg),

            const SectionHeader(title: 'Connectivity'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.isOffline,
                    onChanged: settings.setOffline,
                    secondary: const Icon(Icons.cloud_off_rounded),
                    title: const Text('Offline mode'),
                    subtitle: const Text(
                      'Requests fail; lists fall back to the last saved copy '
                      'and are marked as stale.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: settings.latencyEnabled,
                    onChanged: settings.setLatencyEnabled,
                    secondary: const Icon(Icons.speed_rounded),
                    title: const Text('Artificial latency'),
                    subtitle: const Text('300–800ms per request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),

            SectionHeader(
              title: 'Arm a failure',
              subtitle: settings.fault == SimulatedFault.none
                  ? 'The next request succeeds.'
                  : 'The next request fails with: ${settings.fault.label}',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Insets.sm,
                      runSpacing: Insets.sm,
                      children: [
                        for (final fault in SimulatedFault.values)
                          ChoiceChip(
                            label: Text(fault.label),
                            selected: settings.fault == fault,
                            onSelected: (_) => settings.setFault(
                              fault,
                              oneShot: settings.faultIsOneShot,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: settings.faultIsOneShot,
                      onChanged: (value) =>
                          settings.setFault(settings.fault, oneShot: value),
                      title: const Text('Only once'),
                      subtitle: const Text(
                        'Disarm after a single request instead of failing every call.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            const SectionHeader(
              title: 'Trigger words',
              subtitle:
                  'Put one of these anywhere in a project name or task title '
                  'to make that single save fail.',
            ),
            Card(
              child: Column(
                children: [
                  for (final trigger in MockTriggers.all)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.bolt_rounded, size: 18),
                      title: Text(
                        trigger,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(_triggerDescription(trigger)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),

            const SectionHeader(title: 'Data'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear cached data'),
                    subtitle: const Text(
                      'Empties local storage so offline mode has nothing to show.',
                    ),
                    onTap: () async {
                      await locator<CacheStore>().clearAll();
                      if (!context.mounted) return;
                      AppFeedback.success(context, 'Local cache cleared');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.restart_alt_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('Reset mock data'),
                    subtitle: const Text('Back to the bundled JSON asset'),
                    onTap: () => _resetMockData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),

            Center(
              child: TextButton.icon(
                onPressed: () => settings.reset(),
                icon: const Icon(
                  Icons.settings_backup_restore_rounded,
                  size: 18,
                ),
                label: const Text('Reset all switches'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _triggerDescription(String trigger) {
    return switch (trigger) {
      MockTriggers.serverError => 'Server error (500)',
      MockTriggers.timeout => 'Request times out',
      MockTriggers.validationError => 'Field-level validation error (422)',
      MockTriggers.forbidden => 'Permission denied (403)',
      _ => '',
    };
  }
}
