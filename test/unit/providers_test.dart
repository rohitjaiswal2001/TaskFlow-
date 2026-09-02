import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/domain/entities/task_filter.dart';
import 'package:taskflow/domain/entities/task_item.dart';
import 'package:taskflow/domain/entities/task_status.dart';
import 'package:taskflow/domain/repositories/project_repository.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';
import 'package:taskflow/presentation/providers/member_provider.dart';
import 'package:taskflow/presentation/providers/notification_provider.dart';
import 'package:taskflow/presentation/providers/project_list_provider.dart';
import 'package:taskflow/presentation/providers/task_list_provider.dart';
import 'package:taskflow/presentation/state/view_state.dart';

import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async {
    backend = await TestBackend.create();
    await backend.signIn(TestAccounts.orgAAdmin);
  });
  tearDown(() => backend.dispose());

  group('TaskListProvider state machine', () {
    test('initial -> loading -> success', () async {
      final provider = TaskListProvider(backend.taskRepository);
      expect(provider.state, isA<InitialState<List<TaskItem>>>());

      final future = provider.load();
      expect(provider.state, isA<LoadingState<List<TaskItem>>>());

      await future;
      expect(provider.state, isA<SuccessState<List<TaskItem>>>());
      expect(provider.items, hasLength(11));
    });

    test('a project with no tasks lands on empty, not success', () async {
      final created = await backend.projectRepository.createProject(
        const ProjectDraft(name: 'Fresh', description: 'Nothing here yet'),
      );

      final provider = TaskListProvider(
        backend.taskRepository,
        projectId: created.valueOrNull!.id,
      );
      await provider.load();

      expect(provider.state, isA<EmptyState<List<TaskItem>>>());
      expect(provider.items, isEmpty);
    });

    test('a failed load ends in error', () async {
      final provider = TaskListProvider(backend.taskRepository);
      backend.simulation.setFault(SimulatedFault.serverError);

      await provider.load();

      expect(provider.state, isA<ErrorState<List<TaskItem>>>());
      expect(provider.items, isEmpty);
    });

    test('an error after a good load keeps the data on screen', () async {
      final provider = TaskListProvider(backend.taskRepository);
      await provider.load();

      backend.simulation.setFault(SimulatedFault.serverError);
      await provider.load();

      expect(provider.state, isA<ErrorState<List<TaskItem>>>());
      expect(
        provider.items,
        hasLength(11),
        reason: 'previous data is retained',
      );
    });

    test('loadIfNeeded only fetches once', () async {
      final provider = TaskListProvider(backend.taskRepository);

      await provider.loadIfNeeded();
      backend.simulation.setFault(SimulatedFault.serverError);
      await provider.loadIfNeeded();

      expect(provider.state, isA<SuccessState<List<TaskItem>>>());
    });

    test(
      'a superseded load is dropped rather than overwriting the newer one',
      () async {
        final provider = TaskListProvider(backend.taskRepository);

        final first = provider.load();
        final second = provider.load();
        await Future.wait([first, second]);

        expect(provider.state, isA<SuccessState<List<TaskItem>>>());
        expect(provider.items, hasLength(11));
      },
    );
  });

  group('TaskListProvider filtering and sorting', () {
    late TaskListProvider provider;

    setUp(() async {
      provider = TaskListProvider(backend.taskRepository);
      await provider.load();
    });

    test(
      'filters narrow the visible list without touching the loaded data',
      () {
        provider.setFilter(const TaskFilter(statuses: {TaskStatus.done}));

        expect(provider.items, hasLength(11));
        expect(provider.visibleTasks, hasLength(2));
        expect(provider.isFilteredToNothing, isFalse);
      },
    );

    test('reports when the filter hides everything', () {
      provider.setQuery('nothing matches this');

      expect(provider.visibleTasks, isEmpty);
      expect(provider.isFilteredToNothing, isTrue);
    });

    test('clearing the filter restores the full list', () {
      provider.setFilter(const TaskFilter(priorities: {TaskPriority.urgent}));
      expect(provider.visibleTasks, hasLength(2));

      provider.clearFilter();
      expect(provider.visibleTasks, hasLength(11));
    });

    test('sorting by priority puts urgent first', () {
      provider.setSort(TaskSort.priority);

      expect(provider.visibleTasks.first.priority, TaskPriority.urgent);
    });

    test('sorting by due date pushes undated tasks to the end', () {
      provider.setSort(TaskSort.dueDate);

      final dueDates = provider.visibleTasks.map((t) => t.dueDate).toList();
      final firstNull = dueDates.indexWhere((date) => date == null);
      expect(
        firstNull == -1 || dueDates.skip(firstNull).every((d) => d == null),
        isTrue,
      );
    });
  });

  group('TaskListProvider mutations', () {
    test('a status change is patched in place', () async {
      final provider = TaskListProvider(backend.taskRepository);
      await provider.load();

      await provider.changeStatus('task_2004', TaskStatus.inProgress);

      final task = provider.items.firstWhere((t) => t.id == 'task_2004');
      expect(task.status, TaskStatus.inProgress);
      expect(provider.items, hasLength(11), reason: 'no refetch was needed');
    });

    test('creating a task reloads the list', () async {
      final provider = TaskListProvider(backend.taskRepository);
      await provider.load();

      await provider.create(
        const TaskDraft(
          projectId: 'proj_1001',
          title: 'Another one',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
        ),
      );

      expect(provider.items, hasLength(12));
    });

    test('a rejected mutation leaves the list untouched', () async {
      final provider = TaskListProvider(backend.taskRepository);
      await provider.load();

      final result = await provider.assign('task_2005', 'user_005');

      expect(result.isErr, isTrue);
      expect(
        provider.items.firstWhere((t) => t.id == 'task_2005').assigneeId,
        isNull,
      );
    });
  });

  group('ProjectListProvider', () {
    test('exposes a total task count across projects', () async {
      final provider = ProjectListProvider(backend.projectRepository);
      await provider.load();

      expect(provider.totalTasks, 11);
      expect(provider.byId('proj_1001')?.name, 'Website Relaunch');
      expect(provider.byId('nope'), isNull);
    });

    test('a rebind for a different user clears the state', () async {
      final provider = ProjectListProvider(backend.projectRepository);
      provider.bindSession('user_001');
      await provider.load();
      expect(provider.state, isA<SuccessState>());

      provider.bindSession('user_004');

      expect(provider.state, isA<InitialState>());
      expect(provider.items, isEmpty);
    });
  });

  group('MemberProvider', () {
    test('joins users with their role and indexes them by id', () async {
      final provider = MemberProvider(backend.memberRepository);
      await provider.load();

      expect(provider.items, hasLength(3));
      expect(provider.userById('user_002')?.name, 'Marcus Lee');
      expect(provider.memberById('user_001')?.role.isAdmin, isTrue);
      expect(provider.isMember('user_005'), isFalse, reason: 'other org');
      expect(provider.userById(null), isNull);
    });
  });

  group('NotificationProvider', () {
    test('only shows the signed-in user notifications', () async {
      await backend.authRepository.logout();
      await backend.signIn(TestAccounts.orgAMember);

      final provider = NotificationProvider(backend.notificationRepository);
      await provider.load();

      expect(provider.items, hasLength(1));
      expect(provider.unreadCount, 1);

      await provider.markAllAsRead();
      expect(provider.unreadCount, 0);
    });
  });
}
