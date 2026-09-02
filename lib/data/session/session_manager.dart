import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/errors/api_exception.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/org_role.dart';
import '../datasources/local/cache_store.dart';
import '../datasources/local/session_store.dart';
import '../datasources/remote/taskflow_api.dart';
import '../dto/auth_dto.dart';

class SessionManager {
  SessionManager({
    required SessionStore sessionStore,
    required CacheStore cacheStore,

    required TaskFlowApi Function() apiLocator,
  }) : _store = sessionStore,
       _cache = cacheStore,
       _api = apiLocator;

  final SessionStore _store;
  final CacheStore _cache;
  final TaskFlowApi Function() _api;

  final _changes = StreamController<AuthSession?>.broadcast();

  AuthSession? _current;
  Future<bool>? _inFlightRefresh;

  Stream<AuthSession?> get changes => _changes.stream;

  AuthSession? get current => _current;

  bool get isSignedIn => _current != null;

  AuthSession get requireCurrent {
    final session = _current;
    if (session == null) {
      throw const UnauthorizedFailure('You are not signed in.');
    }
    return session;
  }

  Future<String?> accessToken() async => _current?.accessToken;

  Future<AuthSession?> restore() async {
    final stored = await _store.read();
    if (stored == null) return null;

    _current = stored;

    if (stored.isRefreshTokenExpired()) {
      await signOut();
      return null;
    }

    if (stored.isAccessTokenExpired(leeway: AppConfig.tokenRefreshLeeway)) {
      final refreshed = await refreshTokens();

      if (!refreshed && _current == null) return null;
    }

    _changes.add(_current);
    return _current;
  }

  Future<AuthSession> adopt(AuthResponse response) async {
    final now = DateTime.now();
    final session = AuthSession(
      user: response.user.toEntity(),
      orgId: response.orgId,
      role: OrgRole.fromWire(response.role),
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      accessTokenExpiresAt: now.add(
        Duration(seconds: response.accessTokenExpiresInSeconds),
      ),
      refreshTokenExpiresAt: now.add(
        Duration(seconds: response.refreshTokenExpiresInSeconds),
      ),
    );

    _current = session;
    await _store.write(session);
    _changes.add(session);
    return session;
  }

  Future<bool> refreshTokens() {
    return _inFlightRefresh ??= _refresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<bool> _refresh() async {
    final session = _current;
    if (session == null) return false;

    if (session.isRefreshTokenExpired()) {
      await signOut();
      return false;
    }

    try {
      final response = await _api().refresh(
        RefreshTokenRequest(refreshToken: session.refreshToken),
      );
      await adopt(response);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) await signOut();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    _current = null;
    await _store.clear();
    await _cache.clearAll();
    _changes.add(null);
  }

  void dispose() => _changes.close();
}
