import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../entities/project.dart';

class ProjectDraft {
  const ProjectDraft({
    required this.name,
    required this.description,
    this.status = ProjectStatus.active,
  });

  final String name;
  final String description;
  final ProjectStatus status;
}

abstract interface class ProjectRepository {
  Future<Result<Snapshot<List<Project>>>> getProjects({
    CancellationToken? cancelToken,
  });

  Future<Result<Project>> getProject(
    String projectId, {
    CancellationToken? cancelToken,
  });

  Future<Result<Project>> createProject(ProjectDraft draft);

  Future<Result<Project>> updateProject(String projectId, ProjectDraft draft);

  Future<Result<void>> deleteProject(String projectId);
}
