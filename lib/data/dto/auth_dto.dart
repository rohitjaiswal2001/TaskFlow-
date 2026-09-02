import '../models/user_model.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
  };

  @override
  String toString() => 'LoginRequest(${email.trim()})';
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.organizationName,
  });

  final String name;
  final String email;
  final String password;
  final String organizationName;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim().toLowerCase(),
    'password': password,
    'organization_name': organizationName.trim(),
  };

  @override
  String toString() => 'RegisterRequest(${email.trim()})';
}

class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};

  @override
  String toString() => 'RefreshTokenRequest(****)';
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
    required this.user,
    required this.orgId,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresInSeconds:
          (json['access_token_expires_in_seconds'] as num).toInt(),
      refreshTokenExpiresInSeconds:
          (json['refresh_token_expires_in_seconds'] as num).toInt(),
      user: UserModel.fromJson((json['user'] as Map).cast<String, dynamic>()),
      orgId: json['org_id'] as String,
      role: json['role'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;
  final UserModel user;
  final String orgId;
  final String role;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_token_expires_in_seconds': accessTokenExpiresInSeconds,
    'refresh_token_expires_in_seconds': refreshTokenExpiresInSeconds,
    'user': user.toJson(),
    'org_id': orgId,
    'role': role,
  };

  @override
  String toString() =>
      'AuthResponse(user: ${user.id}, org: $orgId, role: $role)';
}
