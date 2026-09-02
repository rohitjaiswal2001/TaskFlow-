import 'package:equatable/equatable.dart';

import 'app_user.dart';
import 'org_role.dart';

class OrgMember extends Equatable {
  const OrgMember({
    required this.orgId,
    required this.user,
    required this.role,
  });

  final String orgId;
  final AppUser user;
  final OrgRole role;

  String get userId => user.id;

  @override
  List<Object?> get props => [orgId, user, role];
}
