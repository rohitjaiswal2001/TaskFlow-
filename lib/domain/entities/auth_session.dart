import 'package:equatable/equatable.dart';

import 'app_user.dart';
import 'org_role.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.orgId,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  final AppUser user;
  final String orgId;
  final OrgRole role;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;

  bool get isAdmin => role.isAdmin;

  bool isAccessTokenExpired({DateTime? now, Duration leeway = Duration.zero}) {
    final reference = (now ?? DateTime.now()).add(leeway);
    return !reference.isBefore(accessTokenExpiresAt);
  }

  bool isRefreshTokenExpired({DateTime? now}) {
    return !(now ?? DateTime.now()).isBefore(refreshTokenExpiresAt);
  }

  Duration accessTokenTimeLeft({DateTime? now}) {
    final remaining = accessTokenExpiresAt.difference(now ?? DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  AuthSession copyWithTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
  }) {
    return AuthSession(
      user: user,
      orgId: orgId,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
    );
  }

  @override
  List<Object?> get props => [
    user,
    orgId,
    role,
    accessToken,
    refreshToken,
    accessTokenExpiresAt,
    refreshTokenExpiresAt,
  ];

  @override
  String toString() =>
      'AuthSession(user: ${user.id}, org: $orgId, role: ${role.wireName}, '
      'accessTokenExpiresAt: $accessTokenExpiresAt)';
}
