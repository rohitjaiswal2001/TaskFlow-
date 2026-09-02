import '../../core/result/result.dart';
import '../entities/auth_session.dart';

class RegistrationDraft {
  const RegistrationDraft({
    required this.name,
    required this.email,
    required this.password,
    required this.organizationName,
  });

  final String name;
  final String email;
  final String password;
  final String organizationName;
}

class DemoCredential {
  const DemoCredential({
    required this.email,
    required this.password,
    required this.orgId,
    required this.orgName,
    required this.roleLabel,
  });

  final String email;
  final String password;
  final String orgId;
  final String orgName;
  final String roleLabel;
}

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> register(RegistrationDraft draft);

  Future<Result<AuthSession>> refreshSession();

  Future<void> logout();

  Future<Result<List<DemoCredential>>> demoCredentials();
}
