import '../../core/errors/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/taskflow_api.dart';
import '../dto/auth_dto.dart';
import '../session/session_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required TaskFlowApi remoteApi,
    required SessionManager sessionManager,
  }) : _api = remoteApi,
       _session = sessionManager;

  final TaskFlowApi _api;
  final SessionManager _session;

  @override
  Future<AuthSession?> restoreSession() => _session.restore();

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) {
    return Result.guard(() async {
      final response = await _api.login(
        LoginRequest(email: email, password: password),
      );

      return _session.adopt(response);
    });
  }

  @override
  Future<Result<AuthSession>> register(RegistrationDraft draft) {
    return Result.guard(() async {
      final response = await _api.register(
        RegisterRequest(
          name: draft.name,
          email: draft.email,
          password: draft.password,
          organizationName: draft.organizationName,
        ),
      );
      return _session.adopt(response);
    });
  }

  @override
  Future<Result<AuthSession>> refreshSession() {
    return Result.guard(() async {
      final refreshed = await _session.refreshTokens();
      if (!refreshed) {
        throw const UnauthorizedFailure(
          'We could not renew your session. Please sign in again.',
        );
      }
      return _session.requireCurrent;
    });
  }

  @override
  Future<void> logout() => _session.signOut();

  @override
  Future<Result<List<DemoCredential>>> demoCredentials() {
    return Result.guard(() async {
      final credentials = await _api.demoCredentials();
      return credentials.map((dto) => dto.toEntity()).toList(growable: false);
    });
  }
}
