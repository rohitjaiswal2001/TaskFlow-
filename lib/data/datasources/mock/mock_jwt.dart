import 'dart:convert';

abstract final class MockJwt {
  static String issue({
    required String prefix,
    required Map<String, dynamic> claims,
  }) {
    final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
    return '$prefix.$payload.${_checksum(payload)}';
  }

  static Map<String, dynamic>? decode(String token) {
    final segments = token.split('.');
    if (segments.length < 3) return null;

    final signature = segments.last;
    final payload = segments[segments.length - 2];
    if (_checksum(payload) != signature) return null;

    try {
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String _checksum(String input) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

abstract final class JwtClaims {
  static const subject = 'sub';
  static const org = 'org';
  static const role = 'role';
  static const type = 'typ';
  static const issuedAt = 'iat';
  static const expiresAt = 'exp';

  static const tokenId = 'jti';

  static const accessType = 'access';
  static const refreshType = 'refresh';
}
