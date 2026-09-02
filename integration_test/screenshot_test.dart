import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taskflow/app/app.dart';
import 'package:taskflow/app/service_locator.dart';
import 'package:taskflow/data/datasources/mock/mock_database.dart';
import 'package:taskflow/data/session/session_manager.dart';
import 'package:taskflow/presentation/widgets/project_card.dart';
import 'package:taskflow/presentation/widgets/task_tile.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture the main screens', (tester) async {
    await resetDependencies();
    await setUpDependencies();

    await locator<MockDatabase>().reset();
    await locator<SessionManager>().signOut();

    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    await shot('01-login');

    await tester.tap(find.text('Use a demo account'));
    await tester.pumpAndSettle();
    await shot('02-demo-accounts');

    await tester.tap(find.textContaining('Admin · ava.admin').first);
    await tester.pumpAndSettle();
    await shot('03-dashboard');

    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    await shot('04-projects');

    await tester.tap(find.text('Website Relaunch'));
    await tester.pumpAndSettle();
    await shot('05-project-details');

    await tester.tap(find.byType(TaskTile).first);
    await tester.pumpAndSettle();
    await shot('06-task-details');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    await shot('07-task-list');

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await shot('08-filters');
    await tester.tap(find.textContaining('Apply'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New task'));
    await tester.pumpAndSettle();
    await shot('09-new-task');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await shot('10-profile');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await shot('11-dark-mode');

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Developer options'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developer options'));
    await tester.pumpAndSettle();
    await shot('12-developer-options');

    await tester.tap(find.widgetWithText(SwitchListTile, 'Offline mode'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(ProjectCard).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    await shot('13-offline');
  });
}
