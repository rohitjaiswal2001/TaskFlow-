import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/errors/api_exception.dart';
import 'package:taskflow/core/errors/failure.dart';
import 'package:taskflow/data/dto/task_dto.dart';
import 'package:taskflow/domain/entities/task_status.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';

import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async {
    backend = await TestBackend.create();
    await backend.signIn(TestAccounts.orgAAdmin);
  });
  tearDown(() => backend.dispose());

  group('reading', () {
    test('returns every task in the organization', () async {
      final result = await backend.taskRepository.getTasks();

      expect(result.valueOrNull!.value, hasLength(11));
    });

    test('narrows to a single project when asked', () async {
      final result = await backend.taskRepository.getTasks(
        projectId: 'proj_1002',
      );

      expect(result.valueOrNull!.value, hasLength(5));
      expect(
        result.valueOrNull!.value.every(
          (task) => task.projectId == 'proj_1002',
        ),
        isTrue,
      );
    });

    test('a task from another organization is not found', () async {
      final result = await backend.taskRepository.getTask('task_2012');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('an unknown task id is not found', () async {
      final result = await backend.taskRepository.getTask('task_9999');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('comments come back oldest first', () async {
      final result = await backend.taskRepository.getComments('task_2002');
      final comments = result.valueOrNull!;

      expect(comments, hasLength(2));
      expect(comments.first.id, 'cmt_3001');
    });
  });

  group('writing', () {
    test('creates a task inside the chosen project', () async {
      final result = await backend.taskRepository.createTask(
        TaskDraft(
          projectId: 'proj_1001',
          title: 'Ship the changelog',
          description: 'Write release notes for the relaunch.',
          status: TaskStatus.todo,
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 3, 10),
        ),
      );

      final task = result.valueOrNull!;
      expect(task.projectId, 'proj_1001');
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, DateTime(2026, 3, 10));

      final list = await backend.taskRepository.getTasks(
        projectId: 'proj_1001',
      );
      expect(list.valueOrNull!.value, hasLength(7));
    });

    test('status and priority patches only touch that field', () async {
      final before = (await backend.taskRepository.getTask(
        'task_2004',
      )).valueOrNull!;

      final moved = await backend.taskRepository.changeStatus(
        'task_2004',
        TaskStatus.done,
      );
      expect(moved.valueOrNull!.status, TaskStatus.done);
      expect(moved.valueOrNull!.title, before.title);
      expect(moved.valueOrNull!.assigneeId, before.assigneeId);

      final reprioritised = await backend.taskRepository.changePriority(
        'task_2004',
        TaskPriority.low,
      );
      expect(reprioritised.valueOrNull!.priority, TaskPriority.low);
      expect(reprioritised.valueOrNull!.status, TaskStatus.done);
    });

    test('deletes a task and its comments', () async {
      final result = await backend.taskRepository.deleteTask('task_2002');
      expect(result.isOk, isTrue);

      expect(backend.database.findTask('task_2002'), isNull);
      expect(
        backend.database.comments.any((c) => c.taskId == 'task_2002'),
        isFalse,
      );
    });

    test('adds a comment attributed to the signed-in user', () async {
      final result = await backend.taskRepository.addComment(
        'task_2004',
        '  Looking at it  ',
      );

      final comment = result.valueOrNull!;
      expect(comment.body, 'Looking at it');
      expect(comment.authorId, 'user_001');
    });

    test('a title containing #timeout times out', () async {
      final result = await backend.taskRepository.createTask(
        const TaskDraft(
          projectId: 'proj_1001',
          title: 'Slow one #timeout',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
        ),
      );

      expect(result.failureOrNull, isA<TimeoutFailure>());
    });
  });

  group('assignment', () {
    test('assigns a member of the same organization', () async {
      final result = await backend.taskRepository.assign(
        'task_2005',
        'user_003',
      );

      expect(result.valueOrNull!.assigneeId, 'user_003');
    });

    test('notifies the person who was assigned', () async {
      final before = backend.database.notifications.length;

      await backend.taskRepository.assign('task_2005', 'user_003');

      final raised = backend.database.notifications.length - before;
      expect(raised, 1);
      expect(backend.database.notifications.last.userId, 'user_003');
      expect(backend.database.notifications.last.taskId, 'task_2005');
    });

    test('unassigns without touching anything else', () async {
      final result = await backend.taskRepository.unassign('task_2004');

      expect(result.valueOrNull!.assigneeId, isNull);
      expect(result.valueOrNull!.status, TaskStatus.todo);
    });

    test('refuses someone from another organization', () async {
      final result = await backend.taskRepository.assign(
        'task_2005',
        'user_005',
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).fieldErrors,
        contains('assignee_id'),
      );
      expect(backend.database.findTask('task_2005')!.assigneeId, isNull);
    });

    test('the rule holds when the API is called directly', () async {
      expect(
        () => backend.api.patchTask(
          'task_2005',
          const PatchTaskRequest.assignee('user_005'),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('creating a task with a foreign assignee is rejected too', () async {
      final result = await backend.taskRepository.createTask(
        const TaskDraft(
          projectId: 'proj_1001',
          title: 'Cross-org assignment',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          assigneeId: 'user_004',
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
