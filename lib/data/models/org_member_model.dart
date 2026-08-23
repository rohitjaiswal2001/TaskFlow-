import '../../domain/entities/org_member.dart';
import '../../domain/entities/org_role.dart';
import 'user_model.dart';

class OrgMemberModel {
  const OrgMemberModel({
    required this.orgId,
    required this.userId,
    required this.role,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    return OrgMemberModel(
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
    );
  }

  final String orgId;
  final String userId;
  final String role;

  Map<String, dynamic> toJson() => {
    'org_id': orgId,
    'user_id': userId,
    'role': role,
  };

  OrgMember toEntity(UserModel user) => OrgMember(
    orgId: orgId,
    user: user.toEntity(),
    role: OrgRole.fromWire(role),
  );
}
