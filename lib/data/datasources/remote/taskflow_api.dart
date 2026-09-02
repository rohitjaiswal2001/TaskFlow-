import '../../../core/network/cancellation_token.dart';
import '../../dto/api_response.dart';
import '../../dto/auth_dto.dart';
import '../../dto/demo_credential_dto.dart';
import '../../dto/member_dto.dart';
import '../../dto/project_dto.dart';
import '../../dto/task_dto.dart';
import '../../models/comment_model.dart';
import '../../models/notification_model.dart';
import '../../models/organization_model.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';

typedef TokenSupplier = Future<String?> Function();

abstract interface class TaskFlowApi {
  Future<AuthResponse> login(LoginRequest request);

  Future<AuthResponse> register(RegisterRequest request);

  Future<AuthResponse> refresh(RefreshTokenRequest request);

  Future<List<DemoCredentialDto>> demoCredentials();

  Future<ApiResponse<OrganizationModel>> getOrganization({
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<List<MemberResponse>>> getMembers({
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<List<ProjectModel>>> getProjects({
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<ProjectModel>> getProject(
    String projectId, {
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<ProjectModel>> createProject(CreateProjectRequest request);

  Future<ApiResponse<ProjectModel>> updateProject(
    String projectId,
    UpdateProjectRequest request,
  );

  Future<void> deleteProject(String projectId);

  Future<ApiResponse<List<TaskModel>>> getTasks({
    String? projectId,
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<TaskModel>> getTask(
    String taskId, {
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<TaskModel>> createTask(CreateTaskRequest request);

  Future<ApiResponse<TaskModel>> updateTask(
    String taskId,
    UpdateTaskRequest request,
  );

  Future<ApiResponse<TaskModel>> patchTask(
    String taskId,
    PatchTaskRequest request,
  );

  Future<void> deleteTask(String taskId);

  Future<ApiResponse<List<CommentModel>>> getComments(
    String taskId, {
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<CommentModel>> createComment(
    String taskId,
    CreateCommentRequest request,
  );

  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    CancellationToken? cancelToken,
  });

  Future<ApiResponse<NotificationModel>> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();
}
