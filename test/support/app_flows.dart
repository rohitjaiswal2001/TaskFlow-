import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/app/app.dart';
import 'package:taskflow/app/service_locator.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/core/services/biometric_service.dart';
import 'package:taskflow/data/datasources/local/cache_store.dart';
import 'package:taskflow/data/datasources/mock/mock_database.dart';
import 'package:taskflow/data/session/session_manager.dart';
import 'package:taskflow/domain/entities/task_status.dart';
import 'package:taskflow/domain/repositories/auth_repository.dart';
import 'package:taskflow/domain/repositories/member_repository.dart';
import 'package:taskflow/domain/repositories/notification_repository.dart';
import 'package:taskflow/domain/repositories/project_repository.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';
import 'package:taskflow/presentation/widgets/project_card.dart';
import 'package:taskflow/presentation/widgets/task_tile.dart';

import 'fake_biometric_service.dart';
import 'test_backend.dart';

void appFlowTests() {
  late TestBackend backend;

  setUp(() async {
    backend = await TestBackend.create();
    final preferences = await SharedPreferences.getInstance();

    await resetDependencies();
    locator
      ..registerSingleton<SharedPreferences>(preferences)
      ..registerSingleton<SimulationSettings>(backend.simulation)
      ..registerSingleton<BiometricService>(FakeBiometricService())
      ..registerSingleton<CacheStore>(InMemoryCacheStore())
      ..registerSingleton<MockDatabase>(backend.database)
      ..registerSingleton<SessionManager>(backend.sessionManager)
      ..registerSingleton<AuthRepository>(backend.authRepository)
      ..registerSingleton<ProjectRepository>(backend.projectRepository)
      ..registerSingleton<TaskRepository>(backend.taskRepository)
      ..registerSingleton<MemberRepository>(backend.memberRepository)
      ..registerSingleton<NotificationRepository>(
        backend.notificationRepository,
      );
  });

  tearDown(() async {
    backend.dispose();
    await resetDependencies();
  });

  void usePhoneViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1400);
    addTearDown(tester.view.reset);
  }

  Future<void> launch(WidgetTester tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();
  }

  Future<void> signIn(
    WidgetTester tester, {
    String email = TestAccounts.orgAAdmin,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Work email'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      TestAccounts.password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('login lands on the dashboard and logout returns to login', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    await signIn(tester);
    expect(find.textContaining('Ava'), findsWidgets);
    expect(find.text('Nimbus Digital'), findsWidgets);

    await openTab(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Sign out'),
      300,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('projects list and details show the org scoped data', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Projects');

    expect(find.byType(ProjectCard), findsNWidgets(2));
    expect(find.text('Website Relaunch'), findsOneWidget);

    await tester.tap(find.text('Website Relaunch'));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('6 of 6 done'), findsNothing);
    expect(find.byType(TaskTile), findsWidgets);
  });

  testWidgets('a member does not get the admin actions', (tester) async {
    await launch(tester);
    await signIn(tester, email: TestAccounts.orgAMember);
    await openTab(tester, 'Projects');

    expect(find.byType(ProjectCard), findsNWidgets(2));
    expect(
      find.widgetWithText(FloatingActionButton, 'New project'),
      findsNothing,
    );
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  testWidgets('task list renders and filters down to a search term', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Tasks');

    expect(find.byType(TaskTile), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'contact form');
    await tester.pumpAndSettle();

    expect(find.text('Fix broken contact form'), findsOneWidget);
    expect(find.byType(TaskTile), findsOneWidget);
  });

  testWidgets('creating a task adds it to the list', (tester) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Tasks');

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New task'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Website Relaunch').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Verify analytics events',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create task'));
    await tester.pumpAndSettle();

    expect(find.text('Task created'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Verify analytics');
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TaskTile, 'Verify analytics events'),
      findsOneWidget,
    );
  });

  testWidgets('assigning a task from its detail screen', (tester) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Tasks');

    await tester.enterText(find.byType(TextField).first, 'SEO audit');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TaskTile, 'SEO audit'));
    await tester.pumpAndSettle();

    expect(find.text('Unassigned'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Assign'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Priya Nair'));
    await tester.pumpAndSettle();

    expect(find.text('Task assigned'), findsOneWidget);
    expect(backend.database.findTask('task_2005')!.assigneeId, 'user_003');
  });

  testWidgets('updating status from the detail screen', (tester) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Tasks');

    await tester.enterText(find.byType(TextField).first, 'SEO audit');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TaskTile, 'SEO audit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('To do').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('In review').last);
    await tester.pumpAndSettle();

    expect(backend.database.findTask('task_2005')!.status, 'review');
  });

  testWidgets('offline mode keeps the data and says it is saved', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester);
    await openTab(tester, 'Projects');
    expect(find.byType(ProjectCard), findsNWidgets(2));

    backend.simulation.setOffline(true);
    await tester.pumpAndSettle();
    expect(find.text('Offline mode — showing saved data'), findsOneWidget);

    await tester.fling(
      find.byType(ProjectCard).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProjectCard), findsNWidgets(2));
    expect(find.textContaining('Saved copy from'), findsOneWidget);
  });

  testWidgets('registering creates an organization and lands on empty states', (
    tester,
  ) async {
    await launch(tester);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your name'),
      'Sam Reyes',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Organization name'),
      'Brand New Co',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Work email'),
      'sam@brandnew.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sam'), findsWidgets);

    await openTab(tester, 'Projects');
    expect(find.text('No projects yet'), findsOneWidget);

    expect(
      find.widgetWithText(FilledButton, 'Create a project'),
      findsOneWidget,
    );
  });

  testWidgets('the notification inbox opens the task it refers to', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester, email: TestAccounts.orgAMember);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fix broken contact form'), findsOneWidget);

    await tester.tap(find.textContaining('Fix broken contact form'));
    await tester.pumpAndSettle();

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Fix broken contact form'), findsOneWidget);
  });

  testWidgets('a member is blocked by the business logic, not just the UI', (
    tester,
  ) async {
    await backend.signIn(TestAccounts.orgAMember);
    final result = await backend.projectRepository.deleteProject('proj_1001');

    expect(result.isErr, isTrue);
    expect(backend.database.findProject('proj_1001'), isNotNull);
    expect(TaskStatus.values, isNotEmpty);
  });
}
