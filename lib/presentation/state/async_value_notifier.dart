import 'package:flutter/foundation.dart';

import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import 'view_state.dart';

abstract class AsyncValueNotifier<T> extends ChangeNotifier {
  ViewState<T> _state = const InitialState();
  CancellationToken? _inFlight;
  bool _disposed = false;

  ViewState<T> get state => _state;

  T? get value => _state.dataOrNull;

  @protected
  Future<Result<T>> fetch(CancellationToken cancelToken);

  Future<void> loadIfNeeded() {
    if (!_state.isInitial) return Future.value();
    return load();
  }

  Future<void> load({bool silent = false}) async {
    _inFlight?.cancel();
    final token = CancellationToken();
    _inFlight = token;

    if (!silent) emit(LoadingState(previous: _state.dataOrNull));

    final result = await fetch(token);
    if (token.isCancelled || _disposed) return;

    emit(
      result.fold(
        (data) => SuccessState<T>(data, fetchedAt: DateTime.now()),
        (failure) => ErrorState<T>(failure, previous: _state.dataOrNull),
      ),
    );
  }

  Future<void> refresh() => load(silent: true);

  @protected
  void setValue(T next) =>
      emit(SuccessState<T>(next, fetchedAt: DateTime.now()));

  @protected
  void emit(ViewState<T> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _inFlight?.cancel();
    super.dispose();
  }
}
