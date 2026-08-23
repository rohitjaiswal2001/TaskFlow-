import '../../domain/entities/task_comment.dart';

class CommentModel {
  const CommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'author_id': authorId,
    'body': body,
    'created_at': createdAt,
  };

  TaskComment toEntity() => TaskComment(
    id: id,
    taskId: taskId,
    authorId: authorId,
    body: body,
    createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime(2025),
  );
}
