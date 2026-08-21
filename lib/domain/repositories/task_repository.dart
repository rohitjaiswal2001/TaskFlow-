import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../entities/task_comment.dart';
import '../entities/task_item.dart';
import '../entities/task_status.dart';

class TaskDraft {
  const TaskDraft({
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.dueDate,
  });

  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime? dueDate;
}

abstract interface class TaskRepository {
  Future<Result<Snapshot<List<TaskItem>>>> getTasks({
    String? projectId,
    CancellationToken? cancelToken,
  });

  Future<Result<TaskItem>> getTask(
    String taskId, {
    CancellationToken? cancelToken,
  });

  Future<Result<TaskItem>> createTask(TaskDraft draft);

  Future<Result<TaskItem>> updateTask(String taskId, TaskDraft draft);

  Future<Result<void>> deleteTask(String taskId);

  Future<Result<TaskItem>> changeStatus(String taskId, TaskStatus status);

  Future<Result<TaskItem>> changePriority(String taskId, TaskPriority priority);

  Future<Result<TaskItem>> assign(String taskId, String userId);

  Future<Result<TaskItem>> unassign(String taskId);

  Future<Result<List<TaskComment>>> getComments(String taskId);

  Future<Result<TaskComment>> addComment(String taskId, String body);
}
