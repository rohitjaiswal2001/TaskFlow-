class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const {},
  });

  ApiException.offline()
    : statusCode = 0,
      message = 'No internet connection',
      errors = const {};

  ApiException.timeout()
    : statusCode = -1,
      message = 'Connection timed out',
      errors = const {};

  final int statusCode;
  final String message;
  final Map<String, String> errors;

  bool get isOffline => statusCode == 0;
  bool get isTimeout => statusCode == -1;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

class RequestCancelledException implements Exception {
  const RequestCancelledException();

  @override
  String toString() => 'RequestCancelledException';
}

class CacheMissException implements Exception {
  const CacheMissException(this.key);

  final String key;

  @override
  String toString() => 'CacheMissException($key)';
}
