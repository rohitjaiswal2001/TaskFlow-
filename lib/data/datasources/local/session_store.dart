import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/entities/auth_session.dart';
import '../../../domain/entities/org_role.dart';
import '../../models/user_model.dart';

abstract interface class SessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  static const _accessTokenKey = 'taskflow.access_token';
  static const _refreshTokenKey = 'taskflow.refresh_token';
  static const _profileKey = 'taskflow.session_profile';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final rawProfile = await _storage.read(key: _profileKey);

    if (accessToken == null || refreshToken == null || rawProfile == null) {
      return null;
    }

    try {
      final profile = jsonDecode(rawProfile) as Map<String, dynamic>;
      return AuthSession(
        user: UserModel.fromJson(
          (profile['user'] as Map).cast<String, dynamic>(),
        ).toEntity(),
        orgId: profile['org_id'] as String,
        role: OrgRole.fromWire(profile['role'] as String?),
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessTokenExpiresAt: DateTime.parse(
          profile['access_expires_at'] as String,
        ),
        refreshTokenExpiresAt: DateTime.parse(
          profile['refresh_expires_at'] as String,
        ),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final profile = <String, dynamic>{
      'user': UserModel.fromEntity(session.user).toJson(),
      'org_id': session.orgId,
      'role': session.role.wireName,
      'access_expires_at': session.accessTokenExpiresAt.toIso8601String(),
      'refresh_expires_at': session.refreshTokenExpiresAt.toIso8601String(),
    };

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(key: _profileKey, value: jsonEncode(profile)),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _profileKey),
    ]);
  }
}

class InMemorySessionStore implements SessionStore {
  AuthSession? _session;

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;
}
