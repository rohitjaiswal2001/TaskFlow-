import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/datasources/mock/mock_jwt.dart';

void main() {
  const prefix = 'mock.access.token.short_lived';

  test('a token keeps the prefix from the mock payload', () {
    final token = MockJwt.issue(prefix: prefix, claims: {'sub': 'user_001'});

    expect(token, startsWith(prefix));
  });

  test('claims survive a round trip', () {
    final claims = {
      JwtClaims.subject: 'user_001',
      JwtClaims.org: 'org_a1b2c3',
      JwtClaims.role: 'org_admin',
      JwtClaims.type: JwtClaims.accessType,
      JwtClaims.expiresAt: 1893456000,
    };

    final decoded = MockJwt.decode(
      MockJwt.issue(prefix: prefix, claims: claims),
    );

    expect(decoded, claims);
  });

  test('an edited payload no longer verifies', () {
    final token = MockJwt.issue(prefix: prefix, claims: {'role': 'member'});
    final segments = token.split('.');
    final tampered = [
      ...segments.take(segments.length - 2),
      'ZXZpbA',
      segments.last,
    ].join('.');

    expect(MockJwt.decode(tampered), isNull);
  });

  test('garbage decodes to null instead of throwing', () {
    expect(MockJwt.decode(''), isNull);
    expect(MockJwt.decode('not.a.token'), isNull);
    expect(MockJwt.decode('one-segment'), isNull);
  });
}
