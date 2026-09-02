class CreateTaskRequest {
  const CreateTaskRequest({
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.dueDate,
  });

  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'title': title.trim(),
    'description': description.trim(),
    'status': status,
    'priority': priority,
    'assignee_id': assigneeId,
    'due_date': dueDate,
  };
}

class UpdateTaskRequest {
  const UpdateTaskRequest({
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.dueDate,
  });

  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'status': status,
    'priority': priority,
    'assignee_id': assigneeId,
    'due_date': dueDate,
  };
}

class PatchTaskRequest {
  const PatchTaskRequest.status(String value)
    : _field = 'status',
      _value = value;

  const PatchTaskRequest.priority(String value)
    : _field = 'priority',
      _value = value;

  const PatchTaskRequest.assignee(String? userId)
    : _field = 'assignee_id',
      _value = userId;

  final String _field;
  final Object? _value;

  Map<String, dynamic> toJson() => {_field: _value};
}

class CreateCommentRequest {
  const CreateCommentRequest({required this.body});

  final String body;

  Map<String, dynamic> toJson() => {'body': body.trim()};
}
