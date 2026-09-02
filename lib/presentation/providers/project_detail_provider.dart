import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../state/async_value_notifier.dart';

class ProjectDetailProvider extends AsyncValueNotifier<Project> {
  ProjectDetailProvider(this._repository, this.projectId);

  final ProjectRepository _repository;
  final String projectId;

  @override
  Future<Result<Project>> fetch(CancellationToken cancelToken) {
    return _repository.getProject(projectId, cancelToken: cancelToken);
  }

  void applyLocalUpdate(Project project) => setValue(project);
}
