abstract final class Validators {
  static final _emailPattern = RegExp(
    r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? newPassword(String? value) {
    final basic = password(value);
    if (basic != null) return basic;

    final input = value!;
    if (!input.contains(RegExp(r'[A-Za-z]'))) {
      return 'Include at least one letter';
    }
    if (!input.contains(RegExp(r'\d'))) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Name is required';
    if (input.length < 2) return 'Name is too short';
    return null;
  }

  static String? projectName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Project name is required';
    if (input.length < 3) return 'Use at least 3 characters';
    if (input.length > 60) return 'Keep it under 60 characters';
    return null;
  }

  static String? taskTitle(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Title is required';
    if (input.length < 3) return 'Use at least 3 characters';
    if (input.length > 120) return 'Keep it under 120 characters';
    return null;
  }
}
