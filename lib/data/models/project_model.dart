import '../../domain/entities/project.dart';

class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.status,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      taskCount: (json['task_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String orgId;
  final String name;
  final String description;
  final int taskCount;
  final String status;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'description': description,
    'task_count': taskCount,
    'status': status,
    'created_at': createdAt,
  };

  Project toEntity() => Project(
    id: id,
    orgId: orgId,
    name: name,
    description: description,
    taskCount: taskCount,
    status: ProjectStatus.fromWire(status),
    createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime(2025),
  );
}
