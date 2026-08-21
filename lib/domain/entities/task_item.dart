import 'package:equatable/equatable.dart';

import 'task_status.dart';

class TaskItem extends Equatable {
  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.assigneeId,
    this.dueDate,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime? dueDate;
  final DateTime createdAt;

  bool get isAssigned => assigneeId != null;

  bool isOverdue({DateTime? now}) {
    final due = dueDate;
    if (due == null || status.isClosed) return false;
    final today = (now ?? DateTime.now());
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }

  TaskItem copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assigneeId,
    bool clearAssignee = false,
  }) {
    return TaskItem(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    status,
    priority,
    assigneeId,
    dueDate,
    createdAt,
  ];
}
