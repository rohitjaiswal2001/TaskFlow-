import '../../core/network/cancellation_token.dart';
import '../../core/utils/date_format.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local/cache_store.dart';
import '../datasources/remote/api_call_runner.dart';
import '../datasources/remote/taskflow_api.dart';
import '../dto/task_dto.dart';
import '../models/task_model.dart';
import '../session/session_manager.dart';
import 'cache_fallback.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskFlowApi remoteApi,
    required ApiCallRunner callRunner,
    required SessionManager sessionManager,
    required CacheFallback cacheFallback,
  }) : _api = remoteApi,
       _run = callRunner,
       _session = sessionManager,
       _cache = cacheFallback;

  final TaskFlowApi _api;
  final ApiCallRunner _run;
  final SessionManager _session;
  final CacheFallback _cache;

  @override
  Future<Result<Snapshot<List<TaskItem>>>> getTasks({
    String? projectId,
    CancellationToken? cancelToken,
  }) {
    final session = _session.requireCurrent;

    return _cache.load<TaskItem, TaskModel>(
      key: CacheKeys.tasks(session.orgId, projectId),
      fetch: () async {
        final response = await _run.run(
          () => _api.getTasks(projectId: projectId, cancelToken: cancelToken),
        );
        return response.data;
      },
      encode: (model) => model.toJson(),
      decode: TaskModel.fromJson,
      toEntity: (model) => model.toEntity(),
    );
  }

  @override
  Future<Result<TaskItem>> getTask(
    String taskId, {
    CancellationToken? cancelToken,
  }) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.getTask(taskId, cancelToken: cancelToken),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<TaskItem>> createTask(TaskDraft draft) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.createTask(
          CreateTaskRequest(
            projectId: draft.projectId,
            title: draft.title,
            description: draft.description,
            status: draft.status.wireName,
            priority: draft.priority.wireName,
            assigneeId: draft.assigneeId,
            dueDate: _encodeDue(draft.dueDate),
          ),
        ),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<TaskItem>> updateTask(String taskId, TaskDraft draft) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.updateTask(
          taskId,
          UpdateTaskRequest(
            title: draft.title,
            description: draft.description,
            status: draft.status.wireName,
            priority: draft.priority.wireName,
            assigneeId: draft.assigneeId,
            dueDate: _encodeDue(draft.dueDate),
          ),
        ),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<void>> deleteTask(String taskId) {
    return Result.guard(() => _run.run(() => _api.deleteTask(taskId)));
  }

  @override
  Future<Result<TaskItem>> changeStatus(String taskId, TaskStatus status) {
    return _patch(taskId, PatchTaskRequest.status(status.wireName));
  }

  @override
  Future<Result<TaskItem>> changePriority(
    String taskId,
    TaskPriority priority,
  ) {
    return _patch(taskId, PatchTaskRequest.priority(priority.wireName));
  }

  @override
  Future<Result<TaskItem>> assign(String taskId, String userId) {
    return _patch(taskId, PatchTaskRequest.assignee(userId));
  }

  @override
  Future<Result<TaskItem>> unassign(String taskId) {
    return _patch(taskId, const PatchTaskRequest.assignee(null));
  }

  @override
  Future<Result<List<TaskComment>>> getComments(String taskId) {
    return Result.guard(() async {
      final response = await _run.run(() => _api.getComments(taskId));
      return response.data
          .map((model) => model.toEntity())
          .toList(growable: false);
    });
  }

  @override
  Future<Result<TaskComment>> addComment(String taskId, String body) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.createComment(taskId, CreateCommentRequest(body: body)),
      );
      return response.data.toEntity();
    });
  }

  Future<Result<TaskItem>> _patch(String taskId, PatchTaskRequest request) {
    return Result.guard(() async {
      final response = await _run.run(() => _api.patchTask(taskId, request));
      return response.data.toEntity();
    });
  }

  String? _encodeDue(DateTime? value) =>
      value == null ? null : Dates.toDayString(value);
}
