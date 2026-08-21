import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/services/access_policy.dart';
import '../datasources/local/cache_store.dart';
import '../datasources/remote/api_call_runner.dart';
import '../datasources/remote/taskflow_api.dart';
import '../dto/project_dto.dart';
import '../models/project_model.dart';
import '../session/session_manager.dart';
import 'cache_fallback.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({
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
  Future<Result<Snapshot<List<Project>>>> getProjects({
    CancellationToken? cancelToken,
  }) {
    final session = _session.requireCurrent;

    return _cache.load<Project, ProjectModel>(
      key: CacheKeys.projects(session.orgId),
      fetch: () async {
        final response = await _run.run(
          () => _api.getProjects(cancelToken: cancelToken),
        );
        return response.data;
      },
      encode: (model) => model.toJson(),
      decode: ProjectModel.fromJson,
      toEntity: (model) => model.toEntity(),
    );
  }

  @override
  Future<Result<Project>> getProject(
    String projectId, {
    CancellationToken? cancelToken,
  }) {
    return Result.guard(() async {
      final response = await _run.run(
        () => _api.getProject(projectId, cancelToken: cancelToken),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<Project>> createProject(ProjectDraft draft) {
    return Result.guard(() async {
      AccessPolicy.assertCanCreateProject(_session.requireCurrent);

      final response = await _run.run(
        () => _api.createProject(
          CreateProjectRequest(
            name: draft.name,
            description: draft.description,
            status: draft.status.wireName,
          ),
        ),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<Project>> updateProject(String projectId, ProjectDraft draft) {
    return Result.guard(() async {
      AccessPolicy.assertCanEditProject(_session.requireCurrent);

      final response = await _run.run(
        () => _api.updateProject(
          projectId,
          UpdateProjectRequest(
            name: draft.name,
            description: draft.description,
            status: draft.status.wireName,
          ),
        ),
      );
      return response.data.toEntity();
    });
  }

  @override
  Future<Result<void>> deleteProject(String projectId) {
    return Result.guard(() async {
      AccessPolicy.assertCanDeleteProject(_session.requireCurrent);
      await _run.run(() => _api.deleteProject(projectId));
    });
  }
}
