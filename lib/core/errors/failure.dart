import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType($message)';
}

class OfflineFailure extends Failure {
  const OfflineFailure([super.message = 'You appear to be offline.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The request took too long to complete.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'We could not find what you were looking for.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'You do not have permission to do that.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our side.']);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'No saved copy of this data is available.',
  ]);
}

class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Request cancelled.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error.']);
}
