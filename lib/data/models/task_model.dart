import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_status.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeId,
    required this.dueDate,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      assigneeId: json['assignee_id'] as String?,
      dueDate: json['due_date'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? dueDate;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'title': title,
    'description': description,
    'status': status,
    'priority': priority,
    'assignee_id': assigneeId,
    'due_date': dueDate,
    'created_at': createdAt,
  };

  TaskItem toEntity() => TaskItem(
    id: id,
    projectId: projectId,
    title: title,
    description: description,
    status: TaskStatus.fromWire(status),
    priority: TaskPriority.fromWire(priority),
    assigneeId: assigneeId,
    dueDate: DateTime.tryParse(dueDate ?? ''),
    createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime(2025),
  );
}
