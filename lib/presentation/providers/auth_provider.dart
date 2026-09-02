import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/failure.dart';
import '../../core/result/result.dart';
import '../../core/services/biometric_service.dart';
import '../../data/session/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { checking, authenticated, locked, unauthenticated }

enum SignOutReason { manual, inactivity, sessionExpired }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
    required BiometricService biometricService,
    required SharedPreferences preferences,
  }) : _repository = authRepository,
       _sessions = sessionManager,
       _biometrics = biometricService,
       _prefs = preferences {
    _subscription = _sessions.changes.listen(_onSessionChanged);
    _biometricEnabled = _prefs.getBool(_biometricKey) ?? false;
  }

  static const _biometricKey = 'auth.biometric_lock';

  final AuthRepository _repository;
  final SessionManager _sessions;
  final BiometricService _biometrics;
  final SharedPreferences _prefs;

  late final StreamSubscription<AuthSession?> _subscription;
  Timer? _idleTimer;

  AuthStatus _status = AuthStatus.checking;
  AuthSession? _session;
  Failure? _failure;
  bool _isSubmitting = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  SignOutReason? _lastSignOutReason;
  List<DemoCredential> _demoCredentials = const [];

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  Failure? get failure => _failure;
  bool get isSubmitting => _isSubmitting;
  bool get isSignedIn => _session != null;
  bool get isAdmin => _session?.isAdmin ?? false;
  bool get biometricLockEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  SignOutReason? get lastSignOutReason => _lastSignOutReason;
  List<DemoCredential> get demoCredentials => _demoCredentials;

  Future<void> bootstrap() async {
    _biometricAvailable = await _biometrics.isAvailable();

    unawaited(_loadDemoCredentials());

    final restored = await _repository.restoreSession();
    _session = restored;

    if (restored == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    _setStatus(
      _biometricEnabled && _biometricAvailable
          ? AuthStatus.locked
          : AuthStatus.authenticated,
    );
    _restartIdleTimer();
  }

  Future<bool> login({required String email, required String password}) async {
    return _submit(() => _repository.login(email: email, password: password));
  }

  Future<bool> register(RegistrationDraft draft) async {
    return _submit(() => _repository.register(draft));
  }

  Future<bool> refreshTokenNow() async {
    final result = await _repository.refreshSession();

    return result.fold(
      (session) {
        _session = session;
        _failure = null;
        notifyListeners();
        return true;
      },
      (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut({SignOutReason reason = SignOutReason.manual}) async {
    _idleTimer?.cancel();
    _lastSignOutReason = reason;
    await _repository.logout();
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  void clearSignOutReason() {
    if (_lastSignOutReason == null) return;
    _lastSignOutReason = null;
    notifyListeners();
  }

  Future<void> setBiometricLock(bool enabled) async {
    if (enabled && !_biometricAvailable) return;

    _biometricEnabled = enabled;
    await _prefs.setBool(_biometricKey, enabled);
    notifyListeners();
  }

  void lockIfEnabled() {
    if (!_biometricEnabled || !_biometricAvailable) return;
    if (_status != AuthStatus.authenticated) return;

    _setStatus(AuthStatus.locked);
  }

  Future<bool> unlock() async {
    final ok = await _biometrics.authenticate(
      reason: 'Unlock TaskFlow to continue',
    );
    if (!ok) return false;

    _setStatus(AuthStatus.authenticated);
    _restartIdleTimer();
    return true;
  }

  void registerActivity() {
    if (_status != AuthStatus.authenticated) return;
    _restartIdleTimer();
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AppConfig.inactivityTimeout, () {
      if (_status == AuthStatus.unauthenticated) return;
      signOut(reason: SignOutReason.inactivity);
    });
  }

  Future<bool> _submit(Future<Result<AuthSession>> Function() action) async {
    _isSubmitting = true;
    _failure = null;
    notifyListeners();

    final result = await action();
    _isSubmitting = false;

    return result.fold(
      (session) {
        _session = session;
        _lastSignOutReason = null;
        _setStatus(AuthStatus.authenticated);
        _restartIdleTimer();
        return true;
      },
      (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> _loadDemoCredentials() async {
    final result = await _repository.demoCredentials();
    final credentials = result.valueOrNull;
    if (credentials == null) return;

    _demoCredentials = credentials;
    notifyListeners();
  }

  void _onSessionChanged(AuthSession? session) {
    _session = session;

    if (session == null) {
      _idleTimer?.cancel();

      if (_status == AuthStatus.authenticated && _lastSignOutReason == null) {
        _lastSignOutReason = SignOutReason.sessionExpired;
      }
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    if (_status == AuthStatus.checking) return;
    notifyListeners();
  }

  void _setStatus(AuthStatus next) {
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
