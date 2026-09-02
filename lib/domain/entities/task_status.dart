enum TaskStatus {
  todo('todo', 'To do'),
  inProgress('in_progress', 'In progress'),
  review('review', 'In review'),
  done('done', 'Done');

  const TaskStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static TaskStatus fromWire(String? value) => TaskStatus.values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => TaskStatus.todo,
  );

  bool get isClosed => this == TaskStatus.done;

  static const board = [todo, inProgress, review, done];
}

enum TaskPriority {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  urgent('urgent', 'Urgent', 3);

  const TaskPriority(this.wireName, this.label, this.weight);

  final String wireName;
  final String label;
  final int weight;

  static TaskPriority fromWire(String? value) => TaskPriority.values.firstWhere(
    (priority) => priority.wireName == value,
    orElse: () => TaskPriority.medium,
  );
}
