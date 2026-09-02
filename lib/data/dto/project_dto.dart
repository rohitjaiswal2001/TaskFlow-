class CreateProjectRequest {
  const CreateProjectRequest({
    required this.name,
    required this.description,
    required this.status,
  });

  final String name;
  final String description;
  final String status;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'status': status,
  };
}

class UpdateProjectRequest {
  const UpdateProjectRequest({
    required this.name,
    required this.description,
    required this.status,
  });

  final String name;
  final String description;
  final String status;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'status': status,
  };
}
