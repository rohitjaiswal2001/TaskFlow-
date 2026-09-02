import 'package:flutter/material.dart';

import '../../core/result/result.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_status.dart';
import 'app_feedback.dart';
import 'status_chip.dart';

Future<void> showTaskStatusSheet(
  BuildContext context, {
  required TaskItem task,
  required Future<Result<TaskItem>> Function(TaskStatus status) onSelected,
}) async {
  final picked = await showModalBottomSheet<TaskStatus>(
    context: context,
    builder: (sheetContext) => _OptionSheet(
      title: 'Move task to',
      options: [
        for (final status in TaskStatus.values)
          _Option(
            label: status.label,
            color: statusColor(sheetContext, status),
            selected: status == task.status,
            value: status,
          ),
      ],
    ),
  );

  if (picked == null || picked == task.status || !context.mounted) return;

  final result = await onSelected(picked);
  if (!context.mounted) return;

  result.fold(
    (_) =>
        AppFeedback.success(context, 'Moved to ${picked.label.toLowerCase()}'),
    (failure) => AppFeedback.error(context, failure),
  );
}

Future<void> showTaskPrioritySheet(
  BuildContext context, {
  required TaskItem task,
  required Future<Result<TaskItem>> Function(TaskPriority priority) onSelected,
}) async {
  final picked = await showModalBottomSheet<TaskPriority>(
    context: context,
    builder: (sheetContext) => _OptionSheet(
      title: 'Set priority',
      options: [
        for (final priority in TaskPriority.values)
          _Option(
            label: priority.label,
            color: priorityColor(sheetContext, priority),
            selected: priority == task.priority,
            value: priority,
          ),
      ],
    ),
  );

  if (picked == null || picked == task.priority || !context.mounted) return;

  final result = await onSelected(picked);
  if (!context.mounted) return;

  result.fold(
    (_) => AppFeedback.success(
      context,
      'Priority set to ${picked.label.toLowerCase()}',
    ),
    (failure) => AppFeedback.error(context, failure),
  );
}

class _Option<T> {
  const _Option({
    required this.label,
    required this.color,
    required this.selected,
    required this.value,
  });

  final String label;
  final Color color;
  final bool selected;
  final T value;
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({required this.title, required this.options});

  final String title;
  final List<_Option<T>> options;

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
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(option.label),
                trailing: option.selected
                    ? Icon(
                        Icons.check_rounded,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
          ],
        ),
      ),
    );
  }
}
