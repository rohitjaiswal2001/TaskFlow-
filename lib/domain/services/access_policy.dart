import '../../core/errors/failure.dart';
import '../entities/auth_session.dart';
import '../entities/org_role.dart';

abstract final class AccessPolicy {
  static bool canCreateProject(OrgRole role) => role.isAdmin;

  static bool canEditProject(OrgRole role) => role.isAdmin;

  static bool canDeleteProject(OrgRole role) => role.isAdmin;

  static bool canManageMembers(OrgRole role) => role.isAdmin;

  static void assertCanCreateProject(AuthSession session) {
    if (!canCreateProject(session.role)) {
      throw const PermissionFailure(
        'Only organization admins can create projects.',
      );
    }
  }

  static void assertCanEditProject(AuthSession session) {
    if (!canEditProject(session.role)) {
      throw const PermissionFailure(
        'Only organization admins can edit projects.',
      );
    }
  }

  static void assertCanDeleteProject(AuthSession session) {
    if (!canDeleteProject(session.role)) {
      throw const PermissionFailure(
        'Only organization admins can delete projects.',
      );
    }
  }

  static void assertCanManageMembers(AuthSession session) {
    if (!canManageMembers(session.role)) {
      throw const PermissionFailure(
        'Only organization admins can manage members.',
      );
    }
  }

  static void assertSameOrg(AuthSession session, String orgId) {
    if (session.orgId != orgId) {
      throw const NotFoundFailure(
        'That item does not belong to your organization.',
      );
    }
  }
}
