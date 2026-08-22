import 'package:flutter/foundation.dart';

import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import 'view_state.dart';

abstract class AsyncListNotifier<T> extends ChangeNotifier {
  ViewState<List<T>> _state = const InitialState();
  CancellationToken? _inFlight;
  bool _disposed = false;

  ViewState<List<T>> get state => _state;

  List<T> get items => _state.dataOrNull ?? const [];

  bool get hasLoadedOnce => _state.dataOrNull != null;

  @protected
  Future<Result<Snapshot<List<T>>>> fetch(CancellationToken cancelToken);

  @protected
  void onLoaded(List<T> data) {}

  Future<void> loadIfNeeded() {
    if (!_state.isInitial) return Future.value();
    return load();
  }

  Future<void> load({bool silent = false}) async {
    _inFlight?.cancel();
    final token = CancellationToken();
    _inFlight = token;

    if (!silent) {
      _emit(LoadingState(previous: _state.dataOrNull));
    }

    final result = await fetch(token);
    if (token.isCancelled || _disposed) return;

    _emit(
      result.fold(
        (snapshot) {
          onLoaded(snapshot.value);
          return snapshot.value.isEmpty
              ? EmptyState<List<T>>(
                  isStale: snapshot.isStale,
                  fetchedAt: snapshot.fetchedAt,
                )
              : SuccessState<List<T>>(
                  snapshot.value,
                  isStale: snapshot.isStale,
                  fetchedAt: snapshot.fetchedAt,
                );
        },
        (failure) => ErrorState<List<T>>(failure, previous: _state.dataOrNull),
      ),
    );
  }

  Future<void> refresh() => load(silent: true);

  @protected
  void resetQuietly() {
    _inFlight?.cancel();
    _inFlight = null;
    _state = const InitialState();
  }

  @protected
  void replaceItems(List<T> next) {
    _emit(
      next.isEmpty
          ? EmptyState<List<T>>(fetchedAt: _state.fetchedAt)
          : SuccessState<List<T>>(next, fetchedAt: _state.fetchedAt),
    );
  }

  void _emit(ViewState<List<T>> next) {
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

mixin SessionAwareNotifier<T> on AsyncListNotifier<T> {
  String? _boundUserId;

  void bindSession(String? userId) {
    if (userId == _boundUserId) return;
    _boundUserId = userId;
    resetQuietly();
    onSessionCleared();
  }

  @protected
  void onSessionCleared() {}
}
