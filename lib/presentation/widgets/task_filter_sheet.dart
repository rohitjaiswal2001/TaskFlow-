import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_format.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/entities/task_status.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

class TaskFilterSheet extends StatefulWidget {
  const TaskFilterSheet({
    super.key,
    required this.initial,
    required this.members,
  });

  final TaskFilter initial;
  final List<OrgMember> members;

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskFilter _draft = widget.initial;

  Future<void> _pickDueRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange:
          _draft.dueRange.from != null && _draft.dueRange.to != null
          ? DateTimeRange(
              start: _draft.dueRange.from!,
              end: _draft.dueRange.to!,
            )
          : null,
      helpText: 'Filter by due date',
    );

    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        dueRange: DateRange(from: picked.start, to: picked.end),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = _draft.dueRange;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filter tasks', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: _draft.isActive
                      ? () => setState(() => _draft = TaskFilter.empty)
                      : null,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),

            Text('Status', style: theme.textTheme.labelLarge),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: [
                for (final status in TaskStatus.values)
                  FilterChip(
                    label: Text(status.label),
                    selected: _draft.statuses.contains(status),
                    showCheckmark: false,
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: statusColor(context, status),
                    ),
                    onSelected: (_) =>
                        setState(() => _draft = _draft.toggleStatus(status)),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),

            Text('Priority', style: theme.textTheme.labelLarge),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: [
                for (final priority in TaskPriority.values)
                  FilterChip(
                    label: Text(priority.label),
                    selected: _draft.priorities.contains(priority),
                    showCheckmark: false,
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: priorityColor(context, priority),
                    ),
                    onSelected: (_) => setState(
                      () => _draft = _draft.togglePriority(priority),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),

            Text('Assignee', style: theme.textTheme.labelLarge),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              children: [
                ChoiceChip(
                  label: const Text('Anyone'),
                  selected: _draft.assignee is AnyAssignee,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(
                      assignee: const AssigneeFilter.any(),
                    ),
                  ),
                ),
                ChoiceChip(
                  label: const Text('Unassigned'),
                  selected: _draft.assignee is UnassignedOnly,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(
                      assignee: const AssigneeFilter.unassigned(),
                    ),
                  ),
                ),
                for (final member in widget.members)
                  ChoiceChip(
                    avatar: UserAvatar(user: member.user, size: 22),
                    label: Text(member.user.name),
                    selected:
                        _draft.assignee is AssignedTo &&
                        (_draft.assignee as AssignedTo).userId == member.userId,
                    onSelected: (_) => setState(
                      () => _draft = _draft.copyWith(
                        assignee: AssigneeFilter.user(member.userId),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),

            Text('Due date', style: theme.textTheme.labelLarge),
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      range.isEmpty
                          ? 'Any date'
                          : '${Dates.formatDue(range.from!)} → ${Dates.formatDue(range.to!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (!range.isEmpty)
                  IconButton(
                    tooltip: 'Clear dates',
                    onPressed: () => setState(
                      () =>
                          _draft = _draft.copyWith(dueRange: const DateRange()),
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: Insets.xl),

            FilledButton(
              onPressed: () => Navigator.of(context).pop(_draft),
              child: Text(
                _draft.isActive
                    ? 'Apply ${_draft.activeCount} filter(s)'
                    : 'Apply',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
