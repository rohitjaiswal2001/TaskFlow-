import '../../domain/entities/app_notification.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.read,
    required this.taskId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'generic',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      taskId: json['task_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String userId;
  final String type;
  final String message;
  final bool read;
  final String? taskId;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'message': message,
    'read': read,
    'task_id': taskId,
    'created_at': createdAt,
  };

  AppNotification toEntity() => AppNotification(
    id: id,
    userId: userId,
    type: type,
    message: message,
    isRead: read,
    taskId: taskId,
    createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime(2025),
  );
}
