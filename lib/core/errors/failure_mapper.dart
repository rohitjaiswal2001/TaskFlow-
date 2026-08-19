import 'api_exception.dart';
import 'failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) return error;
  if (error is RequestCancelledException) return const CancelledFailure();
  if (error is CacheMissException) return const CacheFailure();

  if (error is ApiException) {
    if (error.isOffline) return OfflineFailure(error.message);
    if (error.isTimeout) return TimeoutFailure(error.message);

    return switch (error.statusCode) {
      400 || 422 => ValidationFailure(error.message, fieldErrors: error.errors),
      401 => UnauthorizedFailure(error.message),
      403 => PermissionFailure(error.message),
      404 => NotFoundFailure(error.message),
      _ => ServerFailure(error.message),
    };
  }

  return UnexpectedFailure(error.toString());
}
