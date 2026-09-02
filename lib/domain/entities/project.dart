import 'package:equatable/equatable.dart';

enum ProjectStatus {
  active('active', 'Active'),
  archived('archived', 'Archived');

  const ProjectStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static ProjectStatus fromWire(String? value) =>
      ProjectStatus.values.firstWhere(
        (status) => status.wireName == value,
        orElse: () => ProjectStatus.active,
      );
}

class Project extends Equatable {
  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orgId;
  final String name;
  final String description;
  final int taskCount;
  final ProjectStatus status;
  final DateTime createdAt;

  Project copyWith({
    String? name,
    String? description,
    int? taskCount,
    ProjectStatus? status,
  }) {
    return Project(
      id: id,
      orgId: orgId,
      name: name ?? this.name,
      description: description ?? this.description,
      taskCount: taskCount ?? this.taskCount,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orgId,
    name,
    description,
    taskCount,
    status,
    createdAt,
  ];
}
