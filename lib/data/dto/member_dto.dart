import '../../domain/entities/org_member.dart';
import '../../domain/entities/org_role.dart';
import '../models/user_model.dart';

class MemberResponse {
  const MemberResponse({
    required this.orgId,
    required this.role,
    required this.user,
  });

  factory MemberResponse.fromJson(Map<String, dynamic> json) {
    return MemberResponse(
      orgId: json['org_id'] as String,
      role: json['role'] as String? ?? 'member',
      user: UserModel.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }

  final String orgId;
  final String role;
  final UserModel user;

  Map<String, dynamic> toJson() => {
    'org_id': orgId,
    'role': role,
    'user': user.toJson(),
  };

  OrgMember toEntity() => OrgMember(
    orgId: orgId,
    user: user.toEntity(),
    role: OrgRole.fromWire(role),
  );
}
