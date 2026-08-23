import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../state/async_list_notifier.dart';

enum TaskSort {
  dueDate('Due date'),
  priority('Priority'),
  recent('Recently added');

  const TaskSort(this.label);

  final String label;
}

class TaskListProvider extends AsyncListNotifier<TaskItem>
    with SessionAwareNotifier<TaskItem> {
  TaskListProvider(this._repository, {this.projectId});

  final TaskRepository _repository;
  final String? projectId;

  TaskFilter _filter = TaskFilter.empty;
  TaskSort _sort = TaskSort.dueDate;
  bool _isMutating = false;

  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  bool get isMutating => _isMutating;

  @override
  Future<Result<Snapshot<List<TaskItem>>>> fetch(
    CancellationToken cancelToken,
  ) {
    return _repository.getTasks(projectId: projectId, cancelToken: cancelToken);
  }

  List<TaskItem> get visibleTasks {
    final filtered = _filter.apply(items);
    return _sortTasks(filtered);
  }

  bool get isFilteredToNothing =>
      items.isNotEmpty && visibleTasks.isEmpty && _filter.isActive;

  void setFilter(TaskFilter next) {
    if (_filter == next) return;
    _filter = next;
    notifyListeners();
  }

  void clearFilter() => setFilter(TaskFilter.empty);

  void setSort(TaskSort next) {
    if (_sort == next) return;
    _sort = next;
    notifyListeners();
  }

  void setQuery(String value) => setFilter(_filter.copyWith(query: value));

  Future<Result<TaskItem>> create(TaskDraft draft) =>
      _mutate(() => _repository.createTask(draft), reload: true);

  Future<Result<TaskItem>> update(String taskId, TaskDraft draft) =>
      _mutate(() => _repository.updateTask(taskId, draft));

  Future<Result<void>> delete(String taskId) =>
      _mutate(() => _repository.deleteTask(taskId), reload: true);

  Future<Result<TaskItem>> changeStatus(String taskId, TaskStatus status) =>
      _mutate(() => _repository.changeStatus(taskId, status));

  Future<Result<TaskItem>> changePriority(
    String taskId,
    TaskPriority priority,
  ) => _mutate(() => _repository.changePriority(taskId, priority));

  Future<Result<TaskItem>> assign(String taskId, String userId) =>
      _mutate(() => _repository.assign(taskId, userId));

  Future<Result<TaskItem>> unassign(String taskId) =>
      _mutate(() => _repository.unassign(taskId));

  void applyLocalUpdate(TaskItem task) {
    final index = items.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    final next = [...items]..[index] = task;
    replaceItems(next);
  }

  void removeLocally(String taskId) {
    if (!items.any((item) => item.id == taskId)) return;
    replaceItems(items.where((item) => item.id != taskId).toList());
  }

  Future<Result<T>> _mutate<T>(
    Future<Result<T>> Function() action, {
    bool reload = false,
  }) async {
    _isMutating = true;
    notifyListeners();

    final result = await action();
    _isMutating = false;

    switch (result) {
      case Ok(:final value) when value is TaskItem && !reload:
        applyLocalUpdate(value);
      case Ok():
        await refresh();
      case Err():
        notifyListeners();
    }

    return result;
  }

  List<TaskItem> _sortTasks(List<TaskItem> tasks) {
    final sorted = [...tasks];

    switch (_sort) {
      case TaskSort.dueDate:
        sorted.sort((a, b) {
          final left = a.dueDate;
          final right = b.dueDate;

          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        });
      case TaskSort.priority:
        sorted.sort((a, b) {
          final byWeight = b.priority.weight.compareTo(a.priority.weight);
          if (byWeight != 0) return byWeight;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      case TaskSort.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sorted;
  }
}
