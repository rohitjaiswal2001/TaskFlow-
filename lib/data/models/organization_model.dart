import '../../domain/entities/organization.dart';

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled organization',
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String name;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };

  Organization toEntity() => Organization(
    id: id,
    name: name,
    createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime(2025),
  );
}
