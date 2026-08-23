import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.taskId,
  });

  final String id;
  final String userId;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? taskId;

  AppNotification markRead() => AppNotification(
    id: id,
    userId: userId,
    type: type,
    message: message,
    isRead: true,
    createdAt: createdAt,
    taskId: taskId,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    message,
    isRead,
    createdAt,
    taskId,
  ];
}
