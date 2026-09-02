import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/presentation/providers/auth_provider.dart';
import 'package:taskflow/presentation/screens/auth/login_screen.dart';

import '../support/pump_app.dart';
import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async => backend = await TestBackend.create());
  tearDown(() => backend.dispose());

  Future<void> pumpLogin(WidgetTester tester) {
    return pumpScreen(tester, backend: backend, child: const LoginScreen());
  }

  Finder emailField() => find.widgetWithText(TextFormField, 'Work email');
  Finder passwordField() => find.widgetWithText(TextFormField, 'Password');
  Finder signInButton() => find.widgetWithText(FilledButton, 'Sign in');

  testWidgets('shows both required-field messages on an empty submit', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(signInButton());
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('rejects a malformed email', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(emailField(), 'not-an-email');
    await tester.enterText(passwordField(), 'Password123!');
    await tester.tap(signInButton());
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('rejects a password that is too short', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(emailField(), TestAccounts.orgAAdmin);
    await tester.enterText(passwordField(), 'abc');
    await tester.tap(signInButton());
    await tester.pump();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('surfaces the server message when the credentials are wrong', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(emailField(), TestAccounts.orgAAdmin);
    await tester.enterText(passwordField(), 'WrongPassword1');
    await tester.tap(signInButton());
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('signs in with a valid mock credential', (tester) async {
    await pumpLogin(tester);
    final auth = Provider.of<AuthProvider>(
      tester.element(find.byType(LoginScreen)),
      listen: false,
    );

    await tester.enterText(emailField(), TestAccounts.orgAAdmin);
    await tester.enterText(passwordField(), TestAccounts.password);
    await tester.tap(signInButton());
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.authenticated);
    expect(auth.session?.user.email, TestAccounts.orgAAdmin);
    expect(auth.isAdmin, isTrue);
  });

  testWidgets('the password stays hidden until the reveal is tapped', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('offers the demo accounts loaded from the data layer', (
    tester,
  ) async {
    await pumpLogin(tester);

    await Provider.of<AuthProvider>(
      tester.element(find.byType(LoginScreen)),
      listen: false,
    ).bootstrap();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use a demo account'));
    await tester.pumpAndSettle();

    expect(find.text('Demo accounts'), findsOneWidget);
    expect(find.textContaining('Nimbus Digital'), findsWidgets);
    expect(find.textContaining('Harborlight Studios'), findsWidgets);
  });
}
