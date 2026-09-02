import 'package:equatable/equatable.dart';

import 'date_range.dart';
import 'task_item.dart';
import 'task_status.dart';

sealed class AssigneeFilter extends Equatable {
  const AssigneeFilter();

  const factory AssigneeFilter.any() = AnyAssignee;
  const factory AssigneeFilter.unassigned() = UnassignedOnly;
  const factory AssigneeFilter.user(String userId) = AssignedTo;

  @override
  List<Object?> get props => const [];
}

class AnyAssignee extends AssigneeFilter {
  const AnyAssignee();
}

class UnassignedOnly extends AssigneeFilter {
  const UnassignedOnly();
}

class AssignedTo extends AssigneeFilter {
  const AssignedTo(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TaskFilter extends Equatable {
  const TaskFilter({
    this.statuses = const {},
    this.priorities = const {},
    this.assignee = const AssigneeFilter.any(),
    this.dueRange = const DateRange(),
    this.query = '',
  });

  static const empty = TaskFilter();

  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final AssigneeFilter assignee;
  final DateRange dueRange;
  final String query;

  bool get isActive => activeCount > 0;

  int get activeCount {
    var count = 0;
    if (statuses.isNotEmpty) count++;
    if (priorities.isNotEmpty) count++;
    if (assignee is! AnyAssignee) count++;
    if (!dueRange.isEmpty) count++;
    if (query.trim().isNotEmpty) count++;
    return count;
  }

  bool matches(TaskItem task) {
    if (statuses.isNotEmpty && !statuses.contains(task.status)) return false;
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }

    switch (assignee) {
      case AnyAssignee():
        break;
      case UnassignedOnly():
        if (task.assigneeId != null) return false;
      case AssignedTo(:final userId):
        if (task.assigneeId != userId) return false;
    }

    if (!dueRange.isEmpty) {
      final due = task.dueDate;
      if (due == null || !dueRange.contains(due)) return false;
    }

    final term = query.trim().toLowerCase();
    if (term.isNotEmpty) {
      final haystack = '${task.title} ${task.description}'.toLowerCase();
      if (!haystack.contains(term)) return false;
    }

    return true;
  }

  List<TaskItem> apply(Iterable<TaskItem> tasks) =>
      tasks.where(matches).toList(growable: false);

  TaskFilter copyWith({
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    AssigneeFilter? assignee,
    DateRange? dueRange,
    String? query,
  }) {
    return TaskFilter(
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      assignee: assignee ?? this.assignee,
      dueRange: dueRange ?? this.dueRange,
      query: query ?? this.query,
    );
  }

  TaskFilter toggleStatus(TaskStatus status) {
    final next = Set<TaskStatus>.from(statuses);
    next.contains(status) ? next.remove(status) : next.add(status);
    return copyWith(statuses: next);
  }

  TaskFilter togglePriority(TaskPriority priority) {
    final next = Set<TaskPriority>.from(priorities);
    next.contains(priority) ? next.remove(priority) : next.add(priority);
    return copyWith(priorities: next);
  }

  @override
  List<Object?> get props => [statuses, priorities, assignee, dueRange, query];
}
