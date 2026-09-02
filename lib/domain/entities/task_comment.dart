import 'package:equatable/equatable.dart';

class TaskComment extends Equatable {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, taskId, authorId, body, createdAt];
}
