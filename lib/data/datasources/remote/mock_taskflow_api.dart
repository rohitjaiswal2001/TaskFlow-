import 'dart:async';

import '../../../core/errors/api_exception.dart';
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
import '../mock/mock_auth_gateway.dart';
import '../mock/mock_database.dart';
import '../mock/network_simulator.dart';
import 'taskflow_api.dart';

class MockTaskFlowApi implements TaskFlowApi {
  MockTaskFlowApi({
    required MockDatabase database,
    required MockAuthGateway authGateway,
    required NetworkSimulator simulator,
    required TokenSupplier tokenSupplier,
  }) : _db = database,
       _auth = authGateway,
       _net = simulator,
       _token = tokenSupplier;

  final MockDatabase _db;
  final MockAuthGateway _auth;
  final NetworkSimulator _net;
  final TokenSupplier _token;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final body = await _public('POST /auth/login', () async {
      return _envelope(_auth.login(request).toJson());
    });
    return AuthResponse.fromJson(_data(body));
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    final body = await _public('POST /auth/register', () async {
      await MockTriggers.check(request.organizationName, field: 'organization');
      return _envelope(_auth.register(request).toJson());
    });
    return AuthResponse.fromJson(_data(body));
  }

  @override
  Future<AuthResponse> refresh(RefreshTokenRequest request) async {
    final body = await _public('POST /auth/refresh', () async {
      return _envelope(_auth.refresh(request).toJson());
    });
    return AuthResponse.fromJson(_data(body));
  }

  @override
  Future<List<DemoCredentialDto>> demoCredentials() async {
    await _db.ensureLoaded();

    return _db.credentials
        .map(
          (credential) => DemoCredentialDto(
            email: credential.email,
            password: credential.password,
            orgId: credential.orgId,
            orgName:
                _db.findOrganization(credential.orgId)?.name ?? 'Unknown org',
            role: credential.role,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ApiResponse<OrganizationModel>> getOrganization({
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /org', cancelToken, (ctx) {
      final org = _db.findOrganization(ctx.orgId);
      if (org == null) {
        throw ApiException(statusCode: 404, message: 'Organization not found.');
      }
      return _envelope(org.toJson());
    });

    return ApiResponse.fromJson(
      body,
      (data) =>
          OrganizationModel.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResponse<List<MemberResponse>>> getMembers({
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /org/members', cancelToken, (ctx) {
      final members = <Map<String, dynamic>>[];

      for (final membership in _db.membersOf(ctx.orgId)) {
        final user = _db.findUser(membership.userId);
        if (user == null) continue;
        members.add(
          MemberResponse(
            orgId: membership.orgId,
            role: membership.role,
            user: user,
          ).toJson(),
        );
      }

      members.sort(
        (a, b) => (a['user'] as Map)['name'].toString().compareTo(
          (b['user'] as Map)['name'].toString(),
        ),
      );

      return _envelope(members, {'count': members.length});
    });

    return ApiResponse.fromJson(
      body,
      (data) => parseList(data, MemberResponse.fromJson),
    );
  }

  @override
  Future<ApiResponse<List<ProjectModel>>> getProjects({
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /projects', cancelToken, (ctx) {
      final rows = _db.projectsOf(ctx.orgId).map(_projectJson).toList()
        ..sort(
          (a, b) => (b['created_at'] as String? ?? '').compareTo(
            a['created_at'] as String? ?? '',
          ),
        );

      return _envelope(rows, {'count': rows.length});
    });

    return ApiResponse.fromJson(
      body,
      (data) => parseList(data, ProjectModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<ProjectModel>> getProject(
    String projectId, {
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /projects/$projectId', cancelToken, (ctx) {
      return _envelope(_projectJson(_requireProject(ctx, projectId)));
    });

    return ApiResponse.fromJson(body, _parseProject);
  }

  @override
  Future<ApiResponse<ProjectModel>> createProject(
    CreateProjectRequest request,
  ) async {
    final body = await _authed('POST /projects', null, (ctx) async {
      _requireAdmin(ctx, 'create projects');
      await MockTriggers.check(request.name, field: 'name');

      final json = request.toJson();
      _requireText(json['name'], field: 'name', label: 'Project name');

      final project = ProjectModel(
        id: _db.nextId('proj'),
        orgId: ctx.orgId,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        taskCount: 0,
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.now().toIso8601String(),
      );

      _db.projects.add(project);
      await _db.commit();
      return _envelope(_projectJson(project));
    });

    return ApiResponse.fromJson(body, _parseProject);
  }

  @override
  Future<ApiResponse<ProjectModel>> updateProject(
    String projectId,
    UpdateProjectRequest request,
  ) async {
    final body = await _authed('PUT /projects/$projectId', null, (ctx) async {
      _requireAdmin(ctx, 'edit projects');
      final existing = _requireProject(ctx, projectId);
      await MockTriggers.check(request.name, field: 'name');

      final json = request.toJson();
      _requireText(json['name'], field: 'name', label: 'Project name');

      final updated = ProjectModel(
        id: existing.id,
        orgId: existing.orgId,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        taskCount: existing.taskCount,
        status: json['status'] as String? ?? existing.status,
        createdAt: existing.createdAt,
      );

      _db.projects[_db.projects.indexOf(existing)] = updated;
      await _db.commit();
      return _envelope(_projectJson(updated));
    });

    return ApiResponse.fromJson(body, _parseProject);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _authed('DELETE /projects/$projectId', null, (ctx) async {
      _requireAdmin(ctx, 'delete projects');
      final project = _requireProject(ctx, projectId);

      final taskIds = _db.tasks
          .where((t) => t.projectId == projectId)
          .map((t) => t.id)
          .toSet();

      _db.projects.remove(project);
      _db.tasks.removeWhere((t) => t.projectId == projectId);
      _db.comments.removeWhere((c) => taskIds.contains(c.taskId));
      _db.notifications.removeWhere((n) => taskIds.contains(n.taskId));

      await _db.commit();
      return _envelope({'id': projectId, 'deleted': true});
    });
  }

  @override
  Future<ApiResponse<List<TaskModel>>> getTasks({
    String? projectId,
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /tasks', cancelToken, (ctx) {
      if (projectId != null) _requireProject(ctx, projectId);

      final scope = _db.projectIdsOf(ctx.orgId);
      final rows =
          _db.tasks
              .where(
                (task) =>
                    scope.contains(task.projectId) &&
                    (projectId == null || task.projectId == projectId),
              )
              .map((task) => task.toJson())
              .toList()
            ..sort(
              (a, b) => (b['created_at'] as String? ?? '').compareTo(
                a['created_at'] as String? ?? '',
              ),
            );

      return _envelope(rows, {'count': rows.length});
    });

    return ApiResponse.fromJson(
      body,
      (data) => parseList(data, TaskModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<TaskModel>> getTask(
    String taskId, {
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /tasks/$taskId', cancelToken, (ctx) {
      return _envelope(_requireTask(ctx, taskId).toJson());
    });

    return ApiResponse.fromJson(body, _parseTask);
  }

  @override
  Future<ApiResponse<TaskModel>> createTask(CreateTaskRequest request) async {
    final body = await _authed('POST /tasks', null, (ctx) async {
      await MockTriggers.check(request.title, field: 'title');

      final json = request.toJson();
      _requireProject(ctx, json['project_id'] as String);
      _requireText(json['title'], field: 'title', label: 'Title');

      final assigneeId = json['assignee_id'] as String?;
      if (assigneeId != null) _requireOrgMember(ctx, assigneeId);

      final task = TaskModel(
        id: _db.nextId('task'),
        projectId: json['project_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'todo',
        priority: json['priority'] as String? ?? 'medium',
        assigneeId: assigneeId,
        dueDate: json['due_date'] as String?,
        createdAt: DateTime.now().toIso8601String(),
      );

      _db.tasks.add(task);
      if (assigneeId != null && assigneeId != ctx.userId) {
        _raiseAssignmentNotification(task, assigneeId);
      }

      await _db.commit();
      return _envelope(task.toJson());
    });

    return ApiResponse.fromJson(body, _parseTask);
  }

  @override
  Future<ApiResponse<TaskModel>> updateTask(
    String taskId,
    UpdateTaskRequest request,
  ) async {
    final body = await _authed('PUT /tasks/$taskId', null, (ctx) async {
      final existing = _requireTask(ctx, taskId);
      await MockTriggers.check(request.title, field: 'title');

      final json = request.toJson();
      _requireText(json['title'], field: 'title', label: 'Title');

      final assigneeId = json['assignee_id'] as String?;
      if (assigneeId != null) _requireOrgMember(ctx, assigneeId);

      final updated = TaskModel(
        id: existing.id,
        projectId: existing.projectId,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? existing.status,
        priority: json['priority'] as String? ?? existing.priority,
        assigneeId: assigneeId,
        dueDate: json['due_date'] as String?,
        createdAt: existing.createdAt,
      );

      _db.tasks[_db.tasks.indexOf(existing)] = updated;
      if (assigneeId != null &&
          assigneeId != existing.assigneeId &&
          assigneeId != ctx.userId) {
        _raiseAssignmentNotification(updated, assigneeId);
      }

      await _db.commit();
      return _envelope(updated.toJson());
    });

    return ApiResponse.fromJson(body, _parseTask);
  }

  @override
  Future<ApiResponse<TaskModel>> patchTask(
    String taskId,
    PatchTaskRequest request,
  ) async {
    final body = await _authed('PATCH /tasks/$taskId', null, (ctx) async {
      final existing = _requireTask(ctx, taskId);
      final patch = request.toJson();

      if (patch.containsKey('assignee_id')) {
        final assigneeId = patch['assignee_id'] as String?;

        if (assigneeId != null) _requireOrgMember(ctx, assigneeId);
      }

      final merged = TaskModel.fromJson({...existing.toJson(), ...patch});
      _db.tasks[_db.tasks.indexOf(existing)] = merged;

      final newAssignee = merged.assigneeId;
      if (patch.containsKey('assignee_id') &&
          newAssignee != null &&
          newAssignee != existing.assigneeId &&
          newAssignee != ctx.userId) {
        _raiseAssignmentNotification(merged, newAssignee);
      }

      await _db.commit();
      return _envelope(merged.toJson());
    });

    return ApiResponse.fromJson(body, _parseTask);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _authed('DELETE /tasks/$taskId', null, (ctx) async {
      final task = _requireTask(ctx, taskId);

      _db.tasks.remove(task);
      _db.comments.removeWhere((c) => c.taskId == taskId);
      _db.notifications.removeWhere((n) => n.taskId == taskId);

      await _db.commit();
      return _envelope({'id': taskId, 'deleted': true});
    });
  }

  @override
  Future<ApiResponse<List<CommentModel>>> getComments(
    String taskId, {
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /tasks/$taskId/comments', cancelToken, (
      ctx,
    ) {
      _requireTask(ctx, taskId);

      final rows =
          _db.comments
              .where((c) => c.taskId == taskId)
              .map((c) => c.toJson())
              .toList()
            ..sort(
              (a, b) => (a['created_at'] as String? ?? '').compareTo(
                b['created_at'] as String? ?? '',
              ),
            );

      return _envelope(rows, {'count': rows.length});
    });

    return ApiResponse.fromJson(
      body,
      (data) => parseList(data, CommentModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<CommentModel>> createComment(
    String taskId,
    CreateCommentRequest request,
  ) async {
    final body = await _authed('POST /tasks/$taskId/comments', null, (
      ctx,
    ) async {
      _requireTask(ctx, taskId);

      final json = request.toJson();
      _requireText(json['body'], field: 'body', label: 'Comment');

      final comment = CommentModel(
        id: _db.nextId('cmt'),
        taskId: taskId,
        authorId: ctx.userId,
        body: json['body'] as String,
        createdAt: DateTime.now().toIso8601String(),
      );

      _db.comments.add(comment);
      await _db.commit();
      return _envelope(comment.toJson());
    });

    return ApiResponse.fromJson(
      body,
      (data) => CommentModel.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    CancellationToken? cancelToken,
  }) async {
    final body = await _authed('GET /notifications', cancelToken, (ctx) {
      final rows =
          _db.notifications
              .where((n) => n.userId == ctx.userId)
              .map((n) => n.toJson())
              .toList()
            ..sort(
              (a, b) => (b['created_at'] as String? ?? '').compareTo(
                a['created_at'] as String? ?? '',
              ),
            );

      return _envelope(rows, {
        'count': rows.length,
        'unread': rows.where((n) => n['read'] == false).length,
      });
    });

    return ApiResponse.fromJson(
      body,
      (data) => parseList(data, NotificationModel.fromJson),
    );
  }

  @override
  Future<ApiResponse<NotificationModel>> markNotificationRead(String id) async {
    final body = await _authed('POST /notifications/$id/read', null, (
      ctx,
    ) async {
      final index = _db.notifications.indexWhere(
        (n) => n.id == id && n.userId == ctx.userId,
      );
      if (index == -1) {
        throw ApiException(statusCode: 404, message: 'Notification not found.');
      }

      final updated = NotificationModel.fromJson({
        ..._db.notifications[index].toJson(),
        'read': true,
      });
      _db.notifications[index] = updated;

      await _db.commit();
      return _envelope(updated.toJson());
    });

    return ApiResponse.fromJson(
      body,
      (data) =>
          NotificationModel.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _authed('POST /notifications/read-all', null, (ctx) async {
      for (var i = 0; i < _db.notifications.length; i++) {
        if (_db.notifications[i].userId != ctx.userId) continue;
        _db.notifications[i] = NotificationModel.fromJson({
          ..._db.notifications[i].toJson(),
          'read': true,
        });
      }

      await _db.commit();
      return _envelope({'updated': true});
    });
  }

  Future<Map<String, dynamic>> _public(
    String endpoint,
    FutureOr<Map<String, dynamic>> Function() handler, {
    CancellationToken? cancelToken,
  }) {
    return _net.send(endpoint, () async {
      await _db.ensureLoaded();
      return handler();
    }, cancelToken: cancelToken);
  }

  Future<Map<String, dynamic>> _authed(
    String endpoint,
    CancellationToken? cancelToken,
    FutureOr<Map<String, dynamic>> Function(AuthContext ctx) handler,
  ) {
    return _net.send(endpoint, () async {
      await _db.ensureLoaded();
      final context = _auth.authenticate(await _token());
      return handler(context);
    }, cancelToken: cancelToken);
  }

  Map<String, dynamic> _envelope(
    Object? data, [
    Map<String, dynamic> meta = const {},
  ]) {
    return {
      'data': data,
      'meta': {'server_time': DateTime.now().toIso8601String(), ...meta},
    };
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) =>
      (body['data'] as Map).cast<String, dynamic>();

  Map<String, dynamic> _projectJson(ProjectModel project) => {
    ...project.toJson(),

    'task_count': _db.taskCountOf(project.id),
  };

  static ProjectModel _parseProject(Object? data) =>
      ProjectModel.fromJson((data as Map).cast<String, dynamic>());

  static TaskModel _parseTask(Object? data) =>
      TaskModel.fromJson((data as Map).cast<String, dynamic>());

  void _requireAdmin(AuthContext ctx, String action) {
    if (!ctx.isAdmin) {
      throw ApiException(
        statusCode: 403,
        message: 'Only organization admins can $action.',
      );
    }
  }

  ProjectModel _requireProject(AuthContext ctx, String projectId) {
    final project = _db.findProject(projectId);
    if (project == null || project.orgId != ctx.orgId) {
      throw ApiException(statusCode: 404, message: 'Project not found.');
    }
    return project;
  }

  TaskModel _requireTask(AuthContext ctx, String taskId) {
    final task = _db.findTask(taskId);
    if (task == null) {
      throw ApiException(statusCode: 404, message: 'Task not found.');
    }
    _requireProject(ctx, task.projectId);
    return task;
  }

  void _requireOrgMember(AuthContext ctx, String userId) {
    if (_db.membership(ctx.orgId, userId) == null) {
      throw ApiException(
        statusCode: 422,
        message: 'That person is not a member of your organization.',
        errors: {'assignee_id': 'Pick someone from your organization.'},
      );
    }
  }

  void _requireText(
    Object? value, {
    required String field,
    required String label,
  }) {
    if (value is! String || value.trim().isEmpty) {
      throw ApiException(
        statusCode: 422,
        message: '$label is required.',
        errors: {field: '$label is required.'},
      );
    }
  }

  void _raiseAssignmentNotification(TaskModel task, String assigneeId) {
    _db.notifications.add(
      NotificationModel(
        id: _db.nextId('notif'),
        userId: assigneeId,
        type: 'task_assigned',
        message: 'You were assigned to "${task.title}"',
        read: false,
        taskId: task.id,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}
