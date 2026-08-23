import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/domain/repositories/auth_repository.dart';
import 'package:taskflow/presentation/screens/tasks/task_list_screen.dart';
import 'package:taskflow/presentation/widgets/skeleton.dart';
import 'package:taskflow/presentation/widgets/task_tile.dart';

import '../support/pump_app.dart';
import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async => backend = await TestBackend.create());
  tearDown(() => backend.dispose());

  Future<void> pumpList(WidgetTester tester) {
    return pumpScreen(tester, backend: backend, child: const TaskListScreen());
  }

  testWidgets('renders the organization tasks once loaded', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonCard), findsNothing);
    expect(find.byType(TaskTile), findsWidgets);
    expect(find.text('Fix broken contact form'), findsOneWidget);

    expect(find.text('Draft onboarding checklist'), findsNothing);
  });

  testWidgets('shows the empty state for a brand new organization', (
    tester,
  ) async {
    await backend.authRepository.register(
      const RegistrationDraft(
        name: 'Sam Reyes',
        email: 'sam@brandnew.test',
        password: 'Password123',
        organizationName: 'Brand New',
      ),
    );

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.byType(TaskTile), findsNothing);
  });

  testWidgets('shows the error state when the request fails', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    backend.simulation.setFault(SimulatedFault.serverError, oneShot: false);

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });

  testWidgets('recovers when the retry succeeds', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    backend.simulation.setFault(SimulatedFault.serverError);

    await pumpList(tester);
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byType(TaskTile), findsWidgets);
  });

  testWidgets('offline data is labelled as saved', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpList(tester);
    await tester.pumpAndSettle();

    backend.simulation.setOffline(true);
    await tester.fling(find.byType(TaskTile).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved copy from'), findsOneWidget);
    expect(find.byType(TaskTile), findsWidgets, reason: 'data stays on screen');
  });

  testWidgets('a search that matches nothing explains why the list is empty', (
    tester,
  ) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpList(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'zzzz-no-match');
    await tester.pumpAndSettle();

    expect(find.text('No matching tasks'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Clear filters'), findsOneWidget);
  });
}
