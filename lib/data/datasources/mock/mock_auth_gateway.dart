import '../../../core/errors/api_exception.dart';
import '../../dto/auth_dto.dart';
import '../../models/credential_model.dart';
import '../../models/org_member_model.dart';
import '../../models/organization_model.dart';
import '../../models/user_model.dart';
import 'mock_database.dart';
import 'mock_jwt.dart';

class AuthContext {
  const AuthContext({
    required this.userId,
    required this.orgId,
    required this.role,
  });

  final String userId;
  final String orgId;
  final String role;

  bool get isAdmin => role == 'org_admin';
}

class MockAuthGateway {
  MockAuthGateway(this._db);

  final MockDatabase _db;

  AuthResponse login(LoginRequest request) {
    final email = request.email.trim().toLowerCase();
    final credential = _db.findCredential(email);

    if (credential == null || !credential.matches(email, request.password)) {
      throw ApiException(
        statusCode: 401,
        message: 'Incorrect email or password.',
      );
    }

    final user = _db.findUserByEmail(email);
    if (user == null) {
      throw ApiException(statusCode: 404, message: 'Account not found.');
    }

    final membership = _db.membership(credential.orgId, user.id);
    return _issue(
      user: user,
      orgId: credential.orgId,
      role: membership?.role ?? credential.role,
    );
  }

  AuthResponse register(RegisterRequest request) {
    final email = request.email.trim().toLowerCase();

    if (_db.findUserByEmail(email) != null) {
      throw ApiException(
        statusCode: 422,
        message: 'That email is already registered.',
        errors: {'email': 'An account with this email already exists.'},
      );
    }

    final orgId = _db.nextId('org');
    final userId = _db.nextId('user');

    _db.organizations.add(
      OrganizationModel(
        id: orgId,
        name: request.organizationName.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final user = UserModel(id: userId, name: request.name.trim(), email: email);
    _db.users.add(user);
    _db.orgMembers.add(
      OrgMemberModel(orgId: orgId, userId: userId, role: 'org_admin'),
    );
    _db.credentials.add(
      CredentialModel(
        email: email,
        password: request.password,
        orgId: orgId,
        role: 'org_admin',
      ),
    );

    return _issue(user: user, orgId: orgId, role: 'org_admin');
  }

  AuthResponse refresh(RefreshTokenRequest request) {
    final claims = MockJwt.decode(request.refreshToken);

    if (claims == null || claims[JwtClaims.type] != JwtClaims.refreshType) {
      throw ApiException(statusCode: 401, message: 'Invalid refresh token.');
    }
    if (_isExpired(claims)) {
      throw ApiException(
        statusCode: 401,
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final user = _db.findUser(claims[JwtClaims.subject] as String?);
    if (user == null) {
      throw ApiException(statusCode: 401, message: 'Account no longer exists.');
    }

    return _issue(
      user: user,
      orgId: claims[JwtClaims.org] as String,
      role: claims[JwtClaims.role] as String,
    );
  }

  AuthContext authenticate(String? bearerToken) {
    if (bearerToken == null || bearerToken.isEmpty) {
      throw ApiException(statusCode: 401, message: 'Missing access token.');
    }

    final claims = MockJwt.decode(bearerToken);
    if (claims == null || claims[JwtClaims.type] != JwtClaims.accessType) {
      throw ApiException(statusCode: 401, message: 'Invalid access token.');
    }
    if (_isExpired(claims)) {
      throw ApiException(statusCode: 401, message: 'Access token expired.');
    }

    final userId = claims[JwtClaims.subject] as String;
    if (_db.findUser(userId) == null) {
      throw ApiException(statusCode: 401, message: 'Account no longer exists.');
    }

    return AuthContext(
      userId: userId,
      orgId: claims[JwtClaims.org] as String,
      role: claims[JwtClaims.role] as String,
    );
  }

  AuthResponse _issue({
    required UserModel user,
    required String orgId,
    required String role,
  }) {
    final template = _db.tokenTemplate;
    final now = DateTime.now();

    String token(String prefix, String type, int lifetimeSeconds) {
      return MockJwt.issue(
        prefix: prefix,
        claims: {
          JwtClaims.subject: user.id,
          JwtClaims.org: orgId,
          JwtClaims.role: role,
          JwtClaims.type: type,
          JwtClaims.tokenId: '${now.microsecondsSinceEpoch}-$type',
          JwtClaims.issuedAt: now.millisecondsSinceEpoch ~/ 1000,
          JwtClaims.expiresAt:
              now
                  .add(Duration(seconds: lifetimeSeconds))
                  .millisecondsSinceEpoch ~/
              1000,
        },
      );
    }

    return AuthResponse(
      accessToken: token(
        template.accessToken,
        JwtClaims.accessType,
        template.accessTokenExpiresInSeconds,
      ),
      refreshToken: token(
        template.refreshToken,
        JwtClaims.refreshType,
        template.refreshTokenExpiresInSeconds,
      ),
      accessTokenExpiresInSeconds: template.accessTokenExpiresInSeconds,
      refreshTokenExpiresInSeconds: template.refreshTokenExpiresInSeconds,
      user: user,
      orgId: orgId,
      role: role,
    );
  }

  bool _isExpired(Map<String, dynamic> claims) {
    final exp = (claims[JwtClaims.expiresAt] as num?)?.toInt();
    if (exp == null) return true;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return !DateTime.now().isBefore(expiresAt);
  }
}
