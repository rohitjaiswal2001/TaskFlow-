import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../state/async_list_notifier.dart';

class ProjectListProvider extends AsyncListNotifier<Project>
    with SessionAwareNotifier<Project> {
  ProjectListProvider(this._repository);

  final ProjectRepository _repository;

  bool _isMutating = false;

  bool get isMutating => _isMutating;

  @override
  Future<Result<Snapshot<List<Project>>>> fetch(CancellationToken cancelToken) {
    return _repository.getProjects(cancelToken: cancelToken);
  }

  Project? byId(String projectId) {
    for (final project in items) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  int get totalTasks =>
      items.fold(0, (sum, project) => sum + project.taskCount);

  Future<Result<Project>> create(ProjectDraft draft) async {
    return _mutate(() => _repository.createProject(draft));
  }

  Future<Result<Project>> update(String projectId, ProjectDraft draft) async {
    return _mutate(() => _repository.updateProject(projectId, draft));
  }

  Future<Result<void>> delete(String projectId) async {
    return _mutate(() => _repository.deleteProject(projectId));
  }

  Future<Result<T>> _mutate<T>(Future<Result<T>> Function() action) async {
    _isMutating = true;
    notifyListeners();

    final result = await action();

    _isMutating = false;
    if (result.isOk) {
      await refresh();
    } else {
      notifyListeners();
    }

    return result;
  }
}
