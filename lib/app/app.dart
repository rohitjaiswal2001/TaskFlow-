import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/config/simulation_settings.dart';
import '../core/services/biometric_service.dart';
import '../data/session/session_manager.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/member_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/member_provider.dart';
import '../presentation/providers/notification_provider.dart';
import '../presentation/providers/project_list_provider.dart';
import '../presentation/providers/settings_provider.dart';
import '../presentation/providers/task_list_provider.dart';
import '../presentation/widgets/activity_detector.dart';
import 'router.dart';
import 'service_locator.dart';

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locator<SimulationSettings>()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(locator<SharedPreferences>()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: locator<AuthRepository>(),
            sessionManager: locator<SessionManager>(),
            biometricService: locator<BiometricService>(),
            preferences: locator<SharedPreferences>(),
          ),
        ),

        ChangeNotifierProxyProvider<AuthProvider, ProjectListProvider>(
          create: (_) => ProjectListProvider(locator<ProjectRepository>()),
          update: (_, auth, provider) =>
              provider!..bindSession(auth.session?.user.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskListProvider>(
          create: (_) => TaskListProvider(locator<TaskRepository>()),
          update: (_, auth, provider) =>
              provider!..bindSession(auth.session?.user.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MemberProvider>(
          create: (_) => MemberProvider(locator<MemberRepository>()),
          update: (_, auth, provider) =>
              provider!..bindSession(auth.session?.user.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) =>
              NotificationProvider(locator<NotificationRepository>()),
          update: (_, auth, provider) =>
              provider!..bindSession(auth.session?.user.id),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter(context.read<AuthProvider>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().registerActivity();
    } else if (state == AppLifecycleState.paused) {
      context.read<AuthProvider>().lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (settings) => settings.themeMode,
    );

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) =>
          ActivityDetector(child: child ?? const SizedBox.shrink()),
    );
  }
}
