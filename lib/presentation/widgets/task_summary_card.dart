import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/entities/task_summary.dart';
import 'status_chip.dart';

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({
    super.key,
    required this.summary,
    this.onStatusTap,
    this.selectedStatus,
  });

  final TaskSummary summary;
  final ValueChanged<TaskStatus>? onStatusTap;
  final TaskStatus? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (summary.completionRatio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Progress', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${summary.completed} of ${summary.total} done',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: summary.completionRatio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              summary.isEmpty ? 'No tasks yet' : '$percent% complete',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.lg),
            Row(
              children: [
                for (final status in TaskStatus.board)
                  Expanded(
                    child: _StatusTile(
                      status: status,
                      count: summary.countOf(status),
                      selected: selectedStatus == status,
                      onTap: onStatusTap == null
                          ? null
                          : () => onStatusTap!(status),
                    ),
                  ),
              ],
            ),
            if (summary.overdue > 0) ...[
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: Insets.xs),
                  Text(
                    summary.overdue == 1
                        ? '1 task is overdue'
                        : '${summary.overdue} tasks are overdue',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.status,
    required this.count,
    required this.selected,
    this.onTap,
  });

  final TaskStatus status;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(context, status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              status.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
