import '../../../core/errors/api_exception.dart';
import '../../session/session_manager.dart';

class ApiCallRunner {
  const ApiCallRunner(this._session);

  final SessionManager _session;

  Future<T> run<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;

      final refreshed = await _session.refreshTokens();
      if (!refreshed) rethrow;

      return request();
    }
  }
}
