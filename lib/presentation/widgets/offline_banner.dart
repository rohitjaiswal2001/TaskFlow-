import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/simulation_settings.dart';
import '../../core/theme/app_spacing.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.select<SimulationSettings, bool>(
      (s) => s.isOffline,
    );
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: isOffline
          ? Material(
              color: theme.colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    Insets.sm,
                    Insets.sm,
                    Insets.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Text(
                          'Offline mode — showing saved data',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context
                            .read<SimulationSettings>()
                            .setOffline(false),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onErrorContainer,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Go online'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
