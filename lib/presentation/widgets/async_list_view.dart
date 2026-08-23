import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../models/failure_display.dart';
import '../state/view_state.dart';
import 'skeleton.dart';
import 'state_views.dart';

class AsyncListView<T> extends StatelessWidget {
  const AsyncListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.builder,
    required this.empty,
    this.skeleton,
    this.banner,
  });

  final ViewState<List<T>> state;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, List<T> items) builder;
  final Widget empty;
  final Widget? skeleton;

  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          if (state.hasStaleData)
            StaleDataBanner(fetchedAt: state.fetchedAt, onRetry: onRefresh),
          if (state case ErrorState(
            :final failure,
          ) when state.dataOrNull != null)
            _InlineErrorStrip(
              message: FailureDisplay.of(failure).message,
              onRetry: onRefresh,
            ),
          ?banner,
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = state.dataOrNull;

    if (data != null && data.isNotEmpty) return builder(context, data);

    return switch (state) {
      InitialState() || LoadingState() => skeleton ?? const SkeletonList(),
      EmptyState() => _Scrollable(child: empty),
      ErrorState(:final failure) => _Scrollable(
        child: ErrorStateView(failure: failure, onRetry: onRefresh),
      ),
      SuccessState(:final data) when data.isEmpty => _Scrollable(child: empty),
      SuccessState() => builder(context, data ?? const []),
    };
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _InlineErrorStrip extends StatelessWidget {
  const _InlineErrorStrip({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.sm,
          Insets.sm,
          Insets.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
