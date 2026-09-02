import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/utils/validators.dart';

void main() {
  group('email', () {
    test('rejects an empty value', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });

    test('rejects malformed addresses', () {
      for (final input in ['nope', 'a@b', 'a b@c.com', '@nimbus.test']) {
        expect(Validators.email(input), isNotNull, reason: input);
      }
    });

    test('accepts the mock credentials', () {
      expect(Validators.email('ava.admin@nimbusdigital.test'), isNull);
      expect(Validators.email('  marcus.member@nimbusdigital.test '), isNull);
    });
  });

  group('password', () {
    test('login only checks length', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('Password123!'), isNull);
      expect(Validators.password('alllowercase'), isNull);
    });

    test('registration also requires a letter and a digit', () {
      expect(Validators.newPassword('12345678'), 'Include at least one letter');
      expect(Validators.newPassword('abcdefgh'), 'Include at least one number');
      expect(Validators.newPassword('abcdefg1'), isNull);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('a', 'b'), 'Passwords do not match');
      expect(Validators.confirmPassword('same', 'same'), isNull);
      expect(Validators.confirmPassword('', 'same'), 'Confirm your password');
    });
  });

  group('project and task fields', () {
    test('project name has a length window', () {
      expect(Validators.projectName('ab'), isNotNull);
      expect(Validators.projectName('Website Relaunch'), isNull);
      expect(Validators.projectName('x' * 61), isNotNull);
    });

    test('task title trims before measuring', () {
      expect(Validators.taskTitle('   '), 'Title is required');
      expect(Validators.taskTitle('  QA pass  '), isNull);
    });
  });
}
