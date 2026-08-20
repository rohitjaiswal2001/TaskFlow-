import 'package:equatable/equatable.dart';

import 'task_item.dart';
import 'task_status.dart';

class TaskSummary extends Equatable {
  const TaskSummary({required this.byStatus, required this.overdue});

  factory TaskSummary.from(Iterable<TaskItem> tasks, {DateTime? now}) {
    final counts = {for (final status in TaskStatus.values) status: 0};
    var overdue = 0;

    for (final task in tasks) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
      if (task.isOverdue(now: now)) overdue++;
    }

    return TaskSummary(byStatus: Map.unmodifiable(counts), overdue: overdue);
  }

  final Map<TaskStatus, int> byStatus;
  final int overdue;

  int countOf(TaskStatus status) => byStatus[status] ?? 0;

  int get total => byStatus.values.fold(0, (sum, value) => sum + value);

  int get completed => countOf(TaskStatus.done);

  double get completionRatio => total == 0 ? 0 : completed / total;

  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => [byStatus, overdue];
}
