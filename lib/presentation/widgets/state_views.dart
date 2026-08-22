import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_format.dart';
import '../models/failure_display.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(Insets.lg),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(icon, size: 30, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: Insets.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Insets.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Insets.xl),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final display = FailureDisplay.of(failure);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(display.icon, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: Insets.lg),
              Text(
                display.title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Insets.sm),
              Text(
                display.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (display.canRetry && onRetry != null) ...[
                const SizedBox(height: Insets.xl),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, this.fetchedAt, this.onRetry});

  final DateTime? fetchedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = fetchedAt;

    return Material(
      color: theme.colorScheme.tertiaryContainer,
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
              Icons.history_rounded,
              size: 18,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                saved == null
                    ? 'Showing saved data — you are offline.'
                    : 'Saved copy from ${Dates.relative(saved)} — you are offline.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class RefreshingIndicator extends StatelessWidget {
  const RefreshingIndicator({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: visible
          ? const LinearProgressIndicator()
          : const SizedBox.shrink(),
    );
  }
}
