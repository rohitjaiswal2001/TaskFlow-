import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';
import '../../core/theme/app_spacing.dart';
import '../models/failure_display.dart';

abstract final class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle_outline_rounded,
      background: Theme.of(context).colorScheme.inverseSurface,
    );
  }

  static void error(BuildContext context, Failure failure) {
    final display = FailureDisplay.of(failure);
    _show(
      context,
      display.message,
      icon: display.icon,
      background: Theme.of(context).colorScheme.error,
      foreground: Theme.of(context).colorScheme.onError,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.info_outline_rounded,
      background: Theme.of(context).colorScheme.inverseSurface,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color background,
    Color? foreground,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final onColor =
        foreground ?? Theme.of(context).colorScheme.onInverseSurface;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, size: 18, color: onColor),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Text(message, style: TextStyle(color: onColor)),
              ),
            ],
          ),
        ),
      );
  }

  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
  }) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
