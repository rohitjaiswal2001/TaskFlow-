import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/domain/entities/task_status.dart';
import 'package:taskflow/presentation/providers/task_list_provider.dart';
import 'package:taskflow/presentation/screens/tasks/task_list_screen.dart';
import 'package:taskflow/presentation/widgets/task_tile.dart';

import '../support/pump_app.dart';
import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async => backend = await TestBackend.create());
  tearDown(() => backend.dispose());

  Finder statusChipOf(String title, String status) {
    return find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(TaskTile)),
      matching: find.text(status),
    );
  }

  TaskListProvider providerOf(WidgetTester tester) {
    return Provider.of<TaskListProvider>(
      tester.element(find.byType(TaskListScreen)),
      listen: false,
    );
  }

  testWidgets('tapping the status pill opens the picker', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpScreen(tester, backend: backend, child: const TaskListScreen());
    await tester.pumpAndSettle();

    await tester.tap(statusChipOf('Fix broken contact form', 'To do'));
    await tester.pumpAndSettle();

    expect(find.text('Move task to'), findsOneWidget);
    for (final status in TaskStatus.values) {
      expect(find.text(status.label), findsWidgets);
    }
  });

  testWidgets('choosing a new status updates the row and confirms it', (
    tester,
  ) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpScreen(tester, backend: backend, child: const TaskListScreen());
    await tester.pumpAndSettle();

    await tester.tap(statusChipOf('Fix broken contact form', 'To do'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('In progress').last);
    await tester.pumpAndSettle();

    final task = providerOf(
      tester,
    ).items.firstWhere((item) => item.id == 'task_2004');
    expect(task.status, TaskStatus.inProgress);

    expect(
      statusChipOf('Fix broken contact form', 'In progress'),
      findsOneWidget,
    );
    expect(find.text('Moved to in progress'), findsOneWidget);
  });

  testWidgets('the change is persisted in the data layer', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpScreen(tester, backend: backend, child: const TaskListScreen());
    await tester.pumpAndSettle();

    await tester.tap(statusChipOf('Fix broken contact form', 'To do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();

    expect(backend.database.findTask('task_2004')!.status, 'done');
  });

  testWidgets('a failed update leaves the row alone and reports the error', (
    tester,
  ) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpScreen(tester, backend: backend, child: const TaskListScreen());
    await tester.pumpAndSettle();

    backend.simulation.setFault(SimulatedFault.serverError);

    await tester.tap(statusChipOf('Fix broken contact form', 'To do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();

    expect(statusChipOf('Fix broken contact form', 'To do'), findsOneWidget);
    expect(find.textContaining('Simulated server error'), findsOneWidget);
  });

  testWidgets('picking the status it already has does nothing', (tester) async {
    await backend.signIn(TestAccounts.orgAAdmin);
    await pumpScreen(tester, backend: backend, child: const TaskListScreen());
    await tester.pumpAndSettle();

    await tester.tap(statusChipOf('Fix broken contact form', 'To do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To do').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Moved to'), findsNothing);
    expect(statusChipOf('Fix broken contact form', 'To do'), findsOneWidget);
  });
}
