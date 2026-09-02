import 'package:flutter/material.dart';

import '../../core/theme/accent_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_format.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/task_item.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.assignee,
    required this.onTap,
    this.projectName,
    this.onStatusTap,
  });

  final TaskItem task;
  final AppUser? assignee;
  final String? projectName;
  final VoidCallback onTap;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.isOverdue();
    final due = task.dueDate;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PriorityBar(priority: task.priority),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (projectName != null) ...[
                        Text(
                          projectName!.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: Insets.xs),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                decoration: task.status.isClosed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.status.isClosed
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Insets.sm),
                          UserAvatar(user: assignee, size: 30),
                        ],
                      ),
                      const SizedBox(height: Insets.md),
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusButton(task: task, onTap: onStatusTap),
                          AccentChip.priority(
                            context,
                            task.priority,
                            dense: true,
                          ),
                          if (due != null)
                            _DueLabel(due: due, isOverdue: overdue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = AccentChip.status(context, task.status, dense: true);
    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: chip,
    );
  }
}

class _DueLabel extends StatelessWidget {
  const _DueLabel({required this.due, required this.isOverdue});

  final DateTime due;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOverdue
        ? context.accents.overdue
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.event_busy_rounded : Icons.event_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          Dates.formatDue(due),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
