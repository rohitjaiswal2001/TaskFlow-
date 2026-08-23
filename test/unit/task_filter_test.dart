import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/entities/date_range.dart';
import 'package:taskflow/domain/entities/task_filter.dart';
import 'package:taskflow/domain/entities/task_item.dart';
import 'package:taskflow/domain/entities/task_status.dart';

TaskItem task({
  String id = 't1',
  String title = 'Build responsive nav component',
  String description = 'Implement the header navigation with mobile drawer.',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  String? assigneeId,
  DateTime? dueDate,
}) {
  return TaskItem(
    id: id,
    projectId: 'proj_1001',
    title: title,
    description: description,
    status: status,
    priority: priority,
    assigneeId: assigneeId,
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('an empty filter matches everything and reports no active facets', () {
    const filter = TaskFilter.empty;

    expect(filter.isActive, isFalse);
    expect(filter.activeCount, 0);
    expect(filter.matches(task()), isTrue);
  });

  test('status and priority sets are OR within, AND across', () {
    const filter = TaskFilter(
      statuses: {TaskStatus.todo, TaskStatus.review},
      priorities: {TaskPriority.urgent},
    );

    expect(
      filter.matches(
        task(status: TaskStatus.todo, priority: TaskPriority.urgent),
      ),
      isTrue,
    );
    expect(
      filter.matches(
        task(status: TaskStatus.review, priority: TaskPriority.urgent),
      ),
      isTrue,
    );

    expect(
      filter.matches(task(status: TaskStatus.todo, priority: TaskPriority.low)),
      isFalse,
    );

    expect(
      filter.matches(
        task(status: TaskStatus.done, priority: TaskPriority.urgent),
      ),
      isFalse,
    );
  });

  group('assignee', () {
    test('unassigned only matches tasks with no owner', () {
      const filter = TaskFilter(assignee: AssigneeFilter.unassigned());

      expect(filter.matches(task(assigneeId: null)), isTrue);
      expect(filter.matches(task(assigneeId: 'user_002')), isFalse);
    });

    test('a specific user matches only their tasks', () {
      const filter = TaskFilter(assignee: AssigneeFilter.user('user_002'));

      expect(filter.matches(task(assigneeId: 'user_002')), isTrue);
      expect(filter.matches(task(assigneeId: 'user_003')), isFalse);
      expect(filter.matches(task(assigneeId: null)), isFalse);
    });
  });

  group('due date range', () {
    final filter = TaskFilter(
      dueRange: DateRange(
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
      ),
    );

    test('includes both boundary days', () {
      expect(filter.matches(task(dueDate: DateTime(2026, 2, 1))), isTrue);
      expect(filter.matches(task(dueDate: DateTime(2026, 2, 28))), isTrue);
    });

    test('excludes dates outside the range and tasks with no due date', () {
      expect(filter.matches(task(dueDate: DateTime(2026, 1, 31))), isFalse);
      expect(filter.matches(task(dueDate: DateTime(2026, 3, 1))), isFalse);
      expect(filter.matches(task(dueDate: null)), isFalse);
    });
  });

  group('text query', () {
    test('is case insensitive and searches the description too', () {
      expect(const TaskFilter(query: 'NAV').matches(task()), isTrue);
      expect(const TaskFilter(query: 'drawer').matches(task()), isTrue);
      expect(const TaskFilter(query: 'invoice').matches(task()), isFalse);
    });

    test('whitespace-only queries are ignored', () {
      expect(const TaskFilter(query: '   ').matches(task()), isTrue);
      expect(const TaskFilter(query: '   ').activeCount, 0);
    });
  });

  test('apply keeps only matching tasks and preserves order', () {
    final tasks = [
      task(id: 'a', status: TaskStatus.todo),
      task(id: 'b', status: TaskStatus.done),
      task(id: 'c', status: TaskStatus.todo),
    ];

    final result = const TaskFilter(statuses: {TaskStatus.todo}).apply(tasks);

    expect(result.map((t) => t.id), ['a', 'c']);
  });

  test('toggling a facet adds then removes it', () {
    final once = TaskFilter.empty.toggleStatus(TaskStatus.done);
    expect(once.statuses, {TaskStatus.done});

    final twice = once.toggleStatus(TaskStatus.done);
    expect(twice.statuses, isEmpty);
    expect(twice.isActive, isFalse);
  });

  test('activeCount counts every applied facet', () {
    final filter = TaskFilter.empty
        .toggleStatus(TaskStatus.todo)
        .togglePriority(TaskPriority.high)
        .copyWith(
          assignee: const AssigneeFilter.user('user_002'),
          query: 'nav',
        );

    expect(filter.activeCount, 4);
  });
}
