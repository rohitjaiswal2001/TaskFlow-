import 'dart:async';

import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../state/async_value_notifier.dart';
import '../state/view_state.dart';

class TaskDetailProvider extends AsyncValueNotifier<TaskItem> {
  TaskDetailProvider(this._repository, this.taskId);

  final TaskRepository _repository;
  final String taskId;

  ViewState<List<TaskComment>> _comments = const InitialState();
  bool _isMutating = false;

  ViewState<List<TaskComment>> get comments => _comments;
  bool get isMutating => _isMutating;

  @override
  Future<Result<TaskItem>> fetch(CancellationToken cancelToken) async {
    final result = await _repository.getTask(taskId, cancelToken: cancelToken);

    if (result.isOk) unawaited(loadComments());
    return result;
  }

  Future<void> loadComments() async {
    _comments = LoadingState(previous: _comments.dataOrNull);
    notifyListeners();

    final result = await _repository.getComments(taskId);

    _comments = result.fold(
      (data) => data.isEmpty
          ? const EmptyState<List<TaskComment>>()
          : SuccessState<List<TaskComment>>(data),
      (failure) => ErrorState<List<TaskComment>>(failure),
    );
    notifyListeners();
  }

  Future<Result<TaskComment>> addComment(String body) async {
    final result = await _repository.addComment(taskId, body);
    if (result.isOk) await loadComments();
    return result;
  }

  Future<Result<TaskItem>> changeStatus(TaskStatus status) =>
      _mutate(() => _repository.changeStatus(taskId, status));

  Future<Result<TaskItem>> changePriority(TaskPriority priority) =>
      _mutate(() => _repository.changePriority(taskId, priority));

  Future<Result<TaskItem>> assign(String userId) =>
      _mutate(() => _repository.assign(taskId, userId));

  Future<Result<TaskItem>> unassign() =>
      _mutate(() => _repository.unassign(taskId));

  Future<Result<void>> delete() async {
    _setMutating(true);
    final result = await _repository.deleteTask(taskId);
    _setMutating(false);
    return result;
  }

  Future<Result<TaskItem>> _mutate(
    Future<Result<TaskItem>> Function() action,
  ) async {
    _setMutating(true);
    final result = await action();
    _isMutating = false;

    result.fold(setValue, (_) => notifyListeners());
    return result;
  }

  void _setMutating(bool value) {
    _isMutating = value;
    notifyListeners();
  }
}
