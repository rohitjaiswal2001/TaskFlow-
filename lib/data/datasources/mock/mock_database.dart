import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/comment_model.dart';
import '../../models/credential_model.dart';
import '../../models/notification_model.dart';
import '../../models/org_member_model.dart';
import '../../models/organization_model.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import 'mock_asset_source.dart';

class MockDatabase {
  MockDatabase(this._assetSource, [this._prefs]);

  static const _snapshotKey = 'mockdb.snapshot.v1';

  final MockAssetSource _assetSource;
  final SharedPreferences? _prefs;

  final List<OrganizationModel> organizations = [];
  final List<UserModel> users = [];
  final List<OrgMemberModel> orgMembers = [];
  final List<ProjectModel> projects = [];
  final List<TaskModel> tasks = [];
  final List<CommentModel> comments = [];
  final List<NotificationModel> notifications = [];

  final List<CredentialModel> credentials = [];

  late TokenTemplateModel tokenTemplate;

  Future<void>? _loading;
  var _sequence = 0;

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final asset = await _assetSource.load();

    _seedFrom(asset);

    final snapshot = _prefs?.getString(_snapshotKey);
    if (snapshot != null) {
      try {
        _applySnapshot(jsonDecode(snapshot) as Map<String, dynamic>);
      } catch (_) {
        await _prefs?.remove(_snapshotKey);
      }
    }
  }

  void _seedFrom(Map<String, dynamic> asset) {
    organizations
      ..clear()
      ..addAll(_parse(asset['organizations'], OrganizationModel.fromJson));
    users
      ..clear()
      ..addAll(_parse(asset['users'], UserModel.fromJson));
    orgMembers
      ..clear()
      ..addAll(_parse(asset['org_members'], OrgMemberModel.fromJson));
    projects
      ..clear()
      ..addAll(_parse(asset['projects'], ProjectModel.fromJson));
    tasks
      ..clear()
      ..addAll(_parse(asset['tasks'], TaskModel.fromJson));
    comments
      ..clear()
      ..addAll(_parse(asset['comments'], CommentModel.fromJson));
    notifications
      ..clear()
      ..addAll(_parse(asset['notifications'], NotificationModel.fromJson));

    final auth = (asset['auth_mock'] as Map?)?.cast<String, dynamic>() ?? {};
    credentials
      ..clear()
      ..addAll(_parse(auth['test_credentials'], CredentialModel.fromJson));
    tokenTemplate = TokenTemplateModel.fromJson(
      (auth['mock_login_response'] as Map?)?.cast<String, dynamic>() ??
          const {},
    );
  }

  void _applySnapshot(Map<String, dynamic> snapshot) {
    void replace<T>(
      List<T> target,
      Object? raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return;
      target
        ..clear()
        ..addAll(_parse(raw, fromJson));
    }

    replace(projects, snapshot['projects'], ProjectModel.fromJson);
    replace(tasks, snapshot['tasks'], TaskModel.fromJson);
    replace(comments, snapshot['comments'], CommentModel.fromJson);
    replace(
      notifications,
      snapshot['notifications'],
      NotificationModel.fromJson,
    );
    _sequence = (snapshot['sequence'] as num?)?.toInt() ?? 0;
  }

  static List<T> _parse<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> commit() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final snapshot = jsonEncode({
      'projects': projects.map((p) => p.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'sequence': _sequence,
    });

    await prefs.setString(_snapshotKey, snapshot);
  }

  Future<void> reset() async {
    await _prefs?.remove(_snapshotKey);
    _loading = null;
    _sequence = 0;
    await ensureLoaded();
  }

  String nextId(String prefix) {
    _sequence++;
    final stamp = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return '${prefix}_${stamp}_$_sequence';
  }

  UserModel? findUser(String? id) =>
      id == null ? null : users.where((u) => u.id == id).firstOrNull;

  UserModel? findUserByEmail(String email) {
    final needle = email.trim().toLowerCase();
    return users.where((u) => u.email.toLowerCase() == needle).firstOrNull;
  }

  OrganizationModel? findOrganization(String id) =>
      organizations.where((o) => o.id == id).firstOrNull;

  ProjectModel? findProject(String id) =>
      projects.where((p) => p.id == id).firstOrNull;

  TaskModel? findTask(String id) => tasks.where((t) => t.id == id).firstOrNull;

  CredentialModel? findCredential(String email) {
    final needle = email.trim().toLowerCase();
    return credentials.where((c) => c.email == needle).firstOrNull;
  }

  OrgMemberModel? membership(String orgId, String userId) => orgMembers
      .where((m) => m.orgId == orgId && m.userId == userId)
      .firstOrNull;

  List<OrgMemberModel> membersOf(String orgId) =>
      orgMembers.where((m) => m.orgId == orgId).toList(growable: false);

  List<ProjectModel> projectsOf(String orgId) =>
      projects.where((p) => p.orgId == orgId).toList(growable: false);

  int taskCountOf(String projectId) =>
      tasks.where((t) => t.projectId == projectId).length;

  Set<String> projectIdsOf(String orgId) =>
      projectsOf(orgId).map((p) => p.id).toSet();
}
