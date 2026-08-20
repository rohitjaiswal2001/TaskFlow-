import 'dart:async';
import 'dart:math';

import '../../../core/config/simulation_settings.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/cancellation_token.dart';
import '../../../core/network/network_status.dart';

class NetworkSimulator {
  NetworkSimulator(
    this._settings,
    this._network, {
    Random? random,
    this.baseLatency,
  }) : _random = random ?? Random();

  final SimulationSettings _settings;

  final NetworkStatus _network;
  final Random _random;

  final Duration? baseLatency;

  Future<T> send<T>(
    String endpoint,
    FutureOr<T> Function() handler, {
    CancellationToken? cancelToken,
  }) async {
    cancelToken?.throwIfCancelled();

    final fault = _settings.takeFault();

    if (fault == SimulatedFault.timeout) {
      await _wait(const Duration(milliseconds: 900));
      cancelToken?.throwIfCancelled();
      throw ApiException.timeout();
    }

    await _wait(_latency());
    cancelToken?.throwIfCancelled();

    if (!_network.isOnline) {
      throw ApiException.offline();
    }

    switch (fault) {
      case SimulatedFault.serverError:
        throw ApiException(
          statusCode: 500,
          message: 'Simulated server error on $endpoint',
        );
      case SimulatedFault.notFound:
        throw ApiException(
          statusCode: 404,
          message: 'Simulated 404 on $endpoint',
        );
      case SimulatedFault.unauthorized:
        throw ApiException(
          statusCode: 401,
          message: 'Simulated expired access token',
        );
      case SimulatedFault.timeout:
      case SimulatedFault.none:
        break;
    }

    final result = await handler();
    cancelToken?.throwIfCancelled();
    return result;
  }

  Duration _latency() {
    final override = baseLatency;
    if (override != null) return override;
    if (!_settings.latencyEnabled) return Duration.zero;

    return Duration(milliseconds: 300 + _random.nextInt(500));
  }

  Future<void> _wait(Duration duration) {
    if (duration == Duration.zero) return Future.value();
    return Future<void>.delayed(duration);
  }
}

abstract final class MockTriggers {
  static const serverError = '#500';
  static const timeout = '#timeout';
  static const validationError = '#invalid';
  static const forbidden = '#403';

  static const all = [serverError, timeout, validationError, forbidden];

  static Future<void> check(String? text, {required String field}) async {
    final value = text?.toLowerCase() ?? '';
    if (value.isEmpty) return;

    if (value.contains(serverError)) {
      throw ApiException(
        statusCode: 500,
        message: 'Simulated server error (triggered by "$serverError")',
      );
    }
    if (value.contains(timeout)) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      throw ApiException.timeout();
    }
    if (value.contains(validationError)) {
      throw ApiException(
        statusCode: 422,
        message: 'The information you entered could not be saved.',
        errors: {
          field: 'Simulated validation error (triggered by "$validationError")',
        },
      );
    }
    if (value.contains(forbidden)) {
      throw ApiException(
        statusCode: 403,
        message: 'Simulated permission error (triggered by "$forbidden")',
      );
    }
  }
}
