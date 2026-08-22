import 'package:flutter/material.dart';

import '../../core/theme/accent_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/task_status.dart';

Color statusColor(BuildContext context, TaskStatus status) {
  final accents = context.accents;
  return switch (status) {
    TaskStatus.todo => accents.todo,
    TaskStatus.inProgress => accents.inProgress,
    TaskStatus.review => accents.review,
    TaskStatus.done => accents.done,
  };
}

Color priorityColor(BuildContext context, TaskPriority priority) {
  final accents = context.accents;
  return switch (priority) {
    TaskPriority.low => accents.priorityLow,
    TaskPriority.medium => accents.priorityMedium,
    TaskPriority.high => accents.priorityHigh,
    TaskPriority.urgent => accents.priorityUrgent,
  };
}

class AccentChip extends StatelessWidget {
  const AccentChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  AccentChip.status(
    BuildContext context,
    TaskStatus status, {
    super.key,
    this.dense = false,
  }) : label = status.label,
       color = statusColor(context, status),
       icon = null;

  AccentChip.priority(
    BuildContext context,
    TaskPriority priority, {
    super.key,
    this.dense = false,
  }) : label = priority.label,
       color = priorityColor(context, priority),
       icon = priority == TaskPriority.urgent
           ? Icons.priority_high_rounded
           : Icons.flag_outlined;

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tint = context.accents.tintOpacity;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Insets.sm : Insets.md,
        vertical: dense ? 2 : Insets.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tint),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                (dense
                        ? Theme.of(context).textTheme.labelSmall
                        : Theme.of(context).textTheme.labelMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class PriorityBar extends StatelessWidget {
  const PriorityBar({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: priorityColor(context, priority),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
    );
  }
}
