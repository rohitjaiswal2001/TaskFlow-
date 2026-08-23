import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/core/network/network_status.dart';
import 'package:taskflow/data/datasources/local/cache_store.dart';
import 'package:taskflow/data/datasources/local/session_store.dart';
import 'package:taskflow/data/datasources/mock/mock_asset_source.dart';
import 'package:taskflow/data/datasources/mock/mock_auth_gateway.dart';
import 'package:taskflow/data/datasources/mock/mock_database.dart';
import 'package:taskflow/data/datasources/mock/network_simulator.dart';
import 'package:taskflow/data/datasources/remote/api_call_runner.dart';
import 'package:taskflow/data/datasources/remote/mock_taskflow_api.dart';
import 'package:taskflow/data/datasources/remote/taskflow_api.dart';
import 'package:taskflow/data/repositories/auth_repository_impl.dart';
import 'package:taskflow/data/repositories/cache_fallback.dart';
import 'package:taskflow/data/repositories/member_repository_impl.dart';
import 'package:taskflow/data/repositories/notification_repository_impl.dart';
import 'package:taskflow/data/repositories/project_repository_impl.dart';
import 'package:taskflow/data/repositories/task_repository_impl.dart';
import 'package:taskflow/data/session/session_manager.dart';
import 'package:taskflow/domain/repositories/auth_repository.dart';
import 'package:taskflow/domain/repositories/member_repository.dart';
import 'package:taskflow/domain/repositories/notification_repository.dart';
import 'package:taskflow/domain/repositories/project_repository.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';

abstract final class TestAccounts {
  static const orgAAdmin = 'ava.admin@nimbusdigital.test';
  static const orgAMember = 'marcus.member@nimbusdigital.test';
  static const orgBAdmin = 'daniel.admin@harborlightstudios.test';
  static const orgBMember = 'elena.member@harborlightstudios.test';
  static const password = 'Password123!';
}

class TestBackend {
  TestBackend._({
    required this.database,
    required this.simulation,
    required this.sessionManager,
    required this.api,
    required this.authRepository,
    required this.projectRepository,
    required this.taskRepository,
    required this.memberRepository,
    required this.notificationRepository,
  });

  static Future<TestBackend> create({Duration latency = Duration.zero}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final payload =
        jsonDecode(
              File(
                'assets/mock_data/taskflow_mock_data.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    final simulation = SimulationSettings(preferences);

    final database = MockDatabase(StaticMockAssetSource(payload));
    final gateway = MockAuthGateway(database);
    final simulator = NetworkSimulator(
      simulation,
      SimulatedNetworkStatus(simulation),
      baseLatency: latency,
    );

    late final TaskFlowApi api;
    final sessionManager = SessionManager(
      sessionStore: InMemorySessionStore(),
      cacheStore: InMemoryCacheStore(),
      apiLocator: () => api,
    );

    api = MockTaskFlowApi(
      database: database,
      authGateway: gateway,
      simulator: simulator,
      tokenSupplier: sessionManager.accessToken,
    );

    final runner = ApiCallRunner(sessionManager);
    final cacheFallback = CacheFallback(InMemoryCacheStore());

    return TestBackend._(
      database: database,
      simulation: simulation,
      sessionManager: sessionManager,
      api: api,
      authRepository: AuthRepositoryImpl(
        remoteApi: api,
        sessionManager: sessionManager,
      ),
      projectRepository: ProjectRepositoryImpl(
        remoteApi: api,
        callRunner: runner,
        sessionManager: sessionManager,
        cacheFallback: cacheFallback,
      ),
      taskRepository: TaskRepositoryImpl(
        remoteApi: api,
        callRunner: runner,
        sessionManager: sessionManager,
        cacheFallback: cacheFallback,
      ),
      memberRepository: MemberRepositoryImpl(
        remoteApi: api,
        callRunner: runner,
        sessionManager: sessionManager,
        cacheFallback: cacheFallback,
      ),
      notificationRepository: NotificationRepositoryImpl(
        remoteApi: api,
        callRunner: runner,
        sessionManager: sessionManager,
        cacheFallback: cacheFallback,
      ),
    );
  }

  final MockDatabase database;
  final SimulationSettings simulation;
  final SessionManager sessionManager;
  final TaskFlowApi api;
  final AuthRepository authRepository;
  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final MemberRepository memberRepository;
  final NotificationRepository notificationRepository;

  Future<void> signIn(String email) async {
    final result = await authRepository.login(
      email: email,
      password: TestAccounts.password,
    );
    if (result.isErr) {
      throw StateError('Test sign-in failed: ${result.failureOrNull}');
    }
  }

  void dispose() => sessionManager.dispose();
}
