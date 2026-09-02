import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/simulation_settings.dart';
import '../core/network/network_status.dart';
import '../core/services/biometric_service.dart';
import '../data/datasources/local/cache_store.dart';
import '../data/datasources/local/session_store.dart';
import '../data/datasources/mock/mock_asset_source.dart';
import '../data/datasources/mock/mock_auth_gateway.dart';
import '../data/datasources/mock/mock_database.dart';
import '../data/datasources/mock/network_simulator.dart';
import '../data/datasources/remote/api_call_runner.dart';
import '../data/datasources/remote/mock_taskflow_api.dart';
import '../data/datasources/remote/taskflow_api.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/cache_fallback.dart';
import '../data/repositories/member_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/project_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/session/session_manager.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/member_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/task_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setUpDependencies() async {
  final preferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(preferences);

  final simulation = SimulationSettings(preferences)..restore();
  final networkStatus = SimulatedNetworkStatus(simulation);
  locator
    ..registerSingleton<SimulationSettings>(simulation)
    ..registerSingleton<NetworkStatus>(networkStatus)
    ..registerSingleton<BiometricService>(BiometricService());

  locator
    ..registerSingleton<CacheStore>(PrefsCacheStore(preferences))
    ..registerSingleton<SessionStore>(
      SecureSessionStore(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      ),
    );

  locator
    ..registerSingleton<MockAssetSource>(BundledMockAssetSource())
    ..registerSingleton<MockDatabase>(
      MockDatabase(locator<MockAssetSource>(), preferences),
    )
    ..registerSingleton<MockAuthGateway>(MockAuthGateway(locator()))
    ..registerSingleton<NetworkSimulator>(
      NetworkSimulator(simulation, networkStatus),
    );

  locator.registerSingleton<SessionManager>(
    SessionManager(
      sessionStore: locator(),
      cacheStore: locator(),
      apiLocator: () => locator<TaskFlowApi>(),
    ),
  );

  locator
    ..registerSingleton<TaskFlowApi>(
      MockTaskFlowApi(
        database: locator(),
        authGateway: locator(),
        simulator: locator(),
        tokenSupplier: () => locator<SessionManager>().accessToken(),
      ),
    )
    ..registerSingleton<ApiCallRunner>(ApiCallRunner(locator()))
    ..registerSingleton<CacheFallback>(CacheFallback(locator<CacheStore>()));

  locator
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(remoteApi: locator(), sessionManager: locator()),
    )
    ..registerSingleton<ProjectRepository>(
      ProjectRepositoryImpl(
        remoteApi: locator(),
        callRunner: locator(),
        sessionManager: locator(),
        cacheFallback: locator(),
      ),
    )
    ..registerSingleton<TaskRepository>(
      TaskRepositoryImpl(
        remoteApi: locator(),
        callRunner: locator(),
        sessionManager: locator(),
        cacheFallback: locator(),
      ),
    )
    ..registerSingleton<MemberRepository>(
      MemberRepositoryImpl(
        remoteApi: locator(),
        callRunner: locator(),
        sessionManager: locator(),
        cacheFallback: locator(),
      ),
    )
    ..registerSingleton<NotificationRepository>(
      NotificationRepositoryImpl(
        remoteApi: locator(),
        callRunner: locator(),
        sessionManager: locator(),
        cacheFallback: locator(),
      ),
    );
}

Future<void> resetDependencies() => locator.reset();
