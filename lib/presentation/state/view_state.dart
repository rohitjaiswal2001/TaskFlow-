import '../../core/errors/failure.dart';

sealed class ViewState<T> {
  const ViewState();

  T? get dataOrNull => switch (this) {
    SuccessState<T>(:final data) => data,
    LoadingState<T>(:final previous) => previous,
    ErrorState<T>(:final previous) => previous,
    _ => null,
  };

  bool get isLoading => this is LoadingState<T>;
  bool get isError => this is ErrorState<T>;
  bool get isSuccess => this is SuccessState<T>;
  bool get isEmpty => this is EmptyState<T>;
  bool get isInitial => this is InitialState<T>;

  bool get isRefreshing => this is LoadingState<T> && dataOrNull != null;

  bool get hasStaleData => switch (this) {
    SuccessState<T>(:final isStale) => isStale,
    EmptyState<T>(:final isStale) => isStale,
    _ => false,
  };

  DateTime? get fetchedAt => switch (this) {
    SuccessState<T>(:final fetchedAt) => fetchedAt,
    EmptyState<T>(:final fetchedAt) => fetchedAt,
    _ => null,
  };
}

final class InitialState<T> extends ViewState<T> {
  const InitialState();
}

final class LoadingState<T> extends ViewState<T> {
  const LoadingState({this.previous});

  final T? previous;
}

final class SuccessState<T> extends ViewState<T> {
  const SuccessState(this.data, {this.isStale = false, this.fetchedAt});

  final T data;
  final bool isStale;

  @override
  final DateTime? fetchedAt;
}

final class EmptyState<T> extends ViewState<T> {
  const EmptyState({this.isStale = false, this.fetchedAt});

  final bool isStale;

  @override
  final DateTime? fetchedAt;
}

final class ErrorState<T> extends ViewState<T> {
  const ErrorState(this.failure, {this.previous});

  final Failure failure;
  final T? previous;
}
