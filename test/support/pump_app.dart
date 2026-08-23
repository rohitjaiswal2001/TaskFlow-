import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/theme/app_theme.dart';
import 'package:taskflow/presentation/providers/auth_provider.dart';
import 'package:taskflow/presentation/providers/member_provider.dart';
import 'package:taskflow/presentation/providers/notification_provider.dart';
import 'package:taskflow/presentation/providers/project_list_provider.dart';
import 'package:taskflow/presentation/providers/task_list_provider.dart';

import 'fake_biometric_service.dart';
import 'test_backend.dart';

Future<void> pumpScreen(
  WidgetTester tester, {
  required TestBackend backend,
  required Widget child,
  List<SingleChildWidget> overrides = const [],
}) async {
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: backend.simulation),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: backend.authRepository,
            sessionManager: backend.sessionManager,
            biometricService: FakeBiometricService(),
            preferences: preferences,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectListProvider(backend.projectRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskListProvider(backend.taskRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => MemberProvider(backend.memberRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(backend.notificationRepository),
        ),
        ...overrides,
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );

  await tester.pump();
}
