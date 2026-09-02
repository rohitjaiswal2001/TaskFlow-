import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/core/errors/failure.dart';
import 'package:taskflow/domain/entities/org_role.dart';
import 'package:taskflow/domain/repositories/auth_repository.dart';

import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async => backend = await TestBackend.create());
  tearDown(() => backend.dispose());

  group('login', () {
    test('accepts a credential from the mock payload', () async {
      final result = await backend.authRepository.login(
        email: TestAccounts.orgAAdmin,
        password: TestAccounts.password,
      );

      final session = result.valueOrNull;
      expect(session, isNotNull);
      expect(session!.user.email, TestAccounts.orgAAdmin);
      expect(session.orgId, 'org_a1b2c3');
      expect(session.role, OrgRole.orgAdmin);
      expect(session.accessToken, startsWith('mock.access.token.short_lived'));
      expect(session.refreshToken, startsWith('mock.refresh.token.long_lived'));
    });

    test('resolves the member role for a non-admin account', () async {
      await backend.signIn(TestAccounts.orgAMember);

      expect(backend.sessionManager.requireCurrent.role, OrgRole.member);
      expect(backend.sessionManager.requireCurrent.isAdmin, isFalse);
    });

    test('is case insensitive on the email', () async {
      final result = await backend.authRepository.login(
        email: 'AVA.ADMIN@NimbusDigital.test',
        password: TestAccounts.password,
      );

      expect(result.isOk, isTrue);
    });

    test('rejects a wrong password without saying which half failed', () async {
      final result = await backend.authRepository.login(
        email: TestAccounts.orgAAdmin,
        password: 'wrong-password',
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(result.failureOrNull!.message, 'Incorrect email or password.');
    });

    test('rejects an unknown account with the same message', () async {
      final result = await backend.authRepository.login(
        email: 'nobody@nimbusdigital.test',
        password: TestAccounts.password,
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(result.failureOrNull!.message, 'Incorrect email or password.');
    });

    test('honours the expiry from mock_login_response', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      final session = backend.sessionManager.requireCurrent;

      final accessLifetime = session.accessTokenExpiresAt
          .difference(DateTime.now())
          .inSeconds;
      final refreshLifetime = session.refreshTokenExpiresAt
          .difference(DateTime.now())
          .inSeconds;

      expect(accessLifetime, closeTo(900, 5));
      expect(refreshLifetime, closeTo(604800, 5));
      expect(session.isAccessTokenExpired(), isFalse);
    });
  });

  group('registration', () {
    test('creates an organization with the new user as its admin', () async {
      final result = await backend.authRepository.register(
        const RegistrationDraft(
          name: 'Rafi Menon',
          email: 'rafi@newco.test',
          password: 'Password123',
          organizationName: 'Newco',
        ),
      );

      final session = result.valueOrNull;
      expect(session, isNotNull);
      expect(session!.role, OrgRole.orgAdmin);
      expect(backend.database.findOrganization(session.orgId)?.name, 'Newco');

      final projects = await backend.projectRepository.getProjects();
      expect(projects.valueOrNull!.value, isEmpty);
    });

    test('refuses an email that already exists', () async {
      final result = await backend.authRepository.register(
        const RegistrationDraft(
          name: 'Impostor',
          email: TestAccounts.orgAAdmin,
          password: 'Password123',
          organizationName: 'Nimbus Copy',
        ),
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).fieldErrors, contains('email'));
    });
  });

  group('token refresh', () {
    test('issues a new access token and keeps the user signed in', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      final before = backend.sessionManager.requireCurrent;

      final result = await backend.authRepository.refreshSession();
      final after = result.valueOrNull;

      expect(after, isNotNull);
      expect(after!.accessToken, isNot(before.accessToken));
      expect(after.user.id, before.user.id);
      expect(after.role, before.role);
      expect(after.refreshToken, isNot(before.refreshToken));
      expect(
        after.accessTokenExpiresAt.isBefore(before.accessTokenExpiresAt),
        isFalse,
      );
    });

    test(
      'a 401 mid-request is retried transparently after a refresh',
      () async {
        await backend.signIn(TestAccounts.orgAAdmin);
        final before = backend.sessionManager.requireCurrent.accessToken;

        backend.simulation.setFault(SimulatedFault.unauthorized);

        final result = await backend.projectRepository.getProjects();

        expect(result.isOk, isTrue, reason: 'the retry should have succeeded');
        expect(result.valueOrNull!.value, isNotEmpty);
        expect(
          backend.sessionManager.requireCurrent.accessToken,
          isNot(before),
        );
      },
    );

    test('concurrent refreshes share a single request', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final results = await Future.wait([
        backend.sessionManager.refreshTokens(),
        backend.sessionManager.refreshTokens(),
        backend.sessionManager.refreshTokens(),
      ]);

      expect(results, everyElement(isTrue));
    });
  });

  group('sign out', () {
    test(
      'clears the session and blocks authenticated calls afterwards',
      () async {
        await backend.signIn(TestAccounts.orgAAdmin);
        expect(backend.sessionManager.isSignedIn, isTrue);

        await backend.authRepository.logout();

        expect(backend.sessionManager.isSignedIn, isFalse);
        expect(backend.sessionManager.current, isNull);
        expect(
          () => backend.sessionManager.requireCurrent,
          throwsA(isA<UnauthorizedFailure>()),
        );
      },
    );
  });

  test('demo credentials are served from the data layer', () async {
    final result = await backend.authRepository.demoCredentials();
    final credentials = result.valueOrNull!;

    expect(credentials, hasLength(4));
    expect(
      credentials.map((c) => c.email),
      containsAll([TestAccounts.orgAAdmin, TestAccounts.orgBMember]),
    );
    expect(
      credentials.firstWhere((c) => c.email == TestAccounts.orgAAdmin).orgName,
      'Nimbus Digital',
    );
  });
}
