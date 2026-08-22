import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/errors/failure.dart';
import '../domain/repositories/project_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/project_detail_provider.dart';
import '../presentation/providers/task_detail_provider.dart';
import '../presentation/providers/task_list_provider.dart';
import '../presentation/screens/auth/lock_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/developer/developer_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/notifications/notification_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/projects/project_detail_screen.dart';
import '../presentation/screens/projects/project_form_screen.dart';
import '../presentation/screens/projects/project_list_screen.dart';
import '../presentation/screens/shell/app_shell.dart';
import '../presentation/screens/tasks/task_detail_screen.dart';
import '../presentation/screens/tasks/task_form_screen.dart';
import '../presentation/screens/tasks/task_list_screen.dart';
import '../presentation/widgets/state_views.dart';
import 'routes.dart';
import 'service_locator.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) => _redirect(auth, state.matchedLocation),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: ErrorStateView(
        failure: NotFoundFailure('There is nothing at "${state.uri}".'),
        onRetry: () => context.go(Routes.home),
      ),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.lock, builder: (_, _) => const LockScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.projects,
                builder: (_, _) => const ProjectListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tasks,
                builder: (_, _) => const TaskListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: Routes.newProject,
        builder: (_, _) => const ProjectFormScreen(),
      ),
      GoRoute(
        path: Routes.projectEdit,
        builder: (_, state) {
          final projectId = state.pathParameters['projectId']!;
          return ChangeNotifierProvider(
            create: (_) =>
                ProjectDetailProvider(locator<ProjectRepository>(), projectId),
            child: ProjectFormScreen(projectId: projectId),
          );
        },
      ),
      GoRoute(
        path: Routes.projectDetail,
        builder: (_, state) {
          final projectId = state.pathParameters['projectId']!;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ProjectDetailProvider(
                  locator<ProjectRepository>(),
                  projectId,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => TaskListProvider(
                  locator<TaskRepository>(),
                  projectId: projectId,
                ),
              ),
            ],
            child: ProjectDetailScreen(projectId: projectId),
          );
        },
      ),

      GoRoute(
        path: Routes.newTask,
        builder: (_, state) => TaskFormScreen(
          initialProjectId: state.uri.queryParameters['projectId'],
        ),
      ),
      GoRoute(
        path: Routes.taskEdit,
        builder: (_, state) {
          final taskId = state.pathParameters['taskId']!;
          return ChangeNotifierProvider(
            create: (_) =>
                TaskDetailProvider(locator<TaskRepository>(), taskId),
            child: TaskFormScreen(taskId: taskId),
          );
        },
      ),
      GoRoute(
        path: Routes.taskDetail,
        builder: (_, state) {
          final taskId = state.pathParameters['taskId']!;
          return ChangeNotifierProvider(
            create: (_) =>
                TaskDetailProvider(locator<TaskRepository>(), taskId),
            child: TaskDetailScreen(taskId: taskId),
          );
        },
      ),

      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationScreen(),
      ),
      GoRoute(
        path: Routes.developer,
        builder: (_, _) => const DeveloperScreen(),
      ),
    ],
  );
}

String? _redirect(AuthProvider auth, String location) {
  const publicRoutes = {Routes.login, Routes.register};

  switch (auth.status) {
    case AuthStatus.checking:
      return location == Routes.splash ? null : Routes.splash;

    case AuthStatus.locked:
      return location == Routes.lock ? null : Routes.lock;

    case AuthStatus.unauthenticated:
      return publicRoutes.contains(location) ? null : Routes.login;

    case AuthStatus.authenticated:
      final onEntryScreen =
          publicRoutes.contains(location) ||
          location == Routes.splash ||
          location == Routes.lock;
      return onEntryScreen ? Routes.home : null;
  }
}
