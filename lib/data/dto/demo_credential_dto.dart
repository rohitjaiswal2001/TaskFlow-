import '../../domain/entities/org_role.dart';
import '../../domain/repositories/auth_repository.dart';

class DemoCredentialDto {
  const DemoCredentialDto({
    required this.email,
    required this.password,
    required this.orgId,
    required this.orgName,
    required this.role,
  });

  factory DemoCredentialDto.fromJson(Map<String, dynamic> json) {
    return DemoCredentialDto(
      email: json['email'] as String,
      password: json['password'] as String,
      orgId: json['org_id'] as String,
      orgName: json['org_name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
    );
  }

  final String email;
  final String password;
  final String orgId;
  final String orgName;
  final String role;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'org_id': orgId,
    'org_name': orgName,
    'role': role,
  };

  DemoCredential toEntity() => DemoCredential(
    email: email,
    password: password,
    orgId: orgId,
    orgName: orgName,
    roleLabel: OrgRole.fromWire(role).label,
  );

  @override
  String toString() => 'DemoCredentialDto($email, $orgName)';
}
