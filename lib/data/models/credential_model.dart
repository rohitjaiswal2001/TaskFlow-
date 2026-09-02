class CredentialModel {
  const CredentialModel({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    return CredentialModel(
      email: (json['email'] as String? ?? '').toLowerCase(),
      password: json['password'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
    );
  }

  final String email;
  final String password;
  final String orgId;
  final String role;

  bool matches(String inputEmail, String inputPassword) =>
      email == inputEmail.trim().toLowerCase() && password == inputPassword;

  @override
  String toString() => 'CredentialModel($email, ****)';
}

class TokenTemplateModel {
  const TokenTemplateModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory TokenTemplateModel.fromJson(Map<String, dynamic> json) {
    return TokenTemplateModel(
      accessToken: json['access_token'] as String? ?? 'mock.access.token',
      refreshToken: json['refresh_token'] as String? ?? 'mock.refresh.token',
      accessTokenExpiresInSeconds:
          (json['access_token_expires_in_seconds'] as num?)?.toInt() ?? 900,
      refreshTokenExpiresInSeconds:
          (json['refresh_token_expires_in_seconds'] as num?)?.toInt() ?? 604800,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;
}
