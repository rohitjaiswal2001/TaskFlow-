import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/errors/failure.dart';
import 'package:taskflow/presentation/state/view_state.dart';
import 'package:taskflow/presentation/widgets/async_list_view.dart';
import 'package:taskflow/presentation/widgets/skeleton.dart';
import 'package:taskflow/presentation/widgets/state_views.dart';

void main() {
  Widget harness(
    ViewState<List<String>> state, {
    Future<void> Function()? onRefresh,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AsyncListView<String>(
          state: state,
          onRefresh: onRefresh ?? () async {},
          empty: const EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'Nothing here',
            message: 'Add something to get started.',
          ),
          builder: (context, items) =>
              ListView(children: [for (final item in items) Text(item)]),
        ),
      ),
    );
  }

  testWidgets('initial and loading render skeletons', (tester) async {
    await tester.pumpWidget(harness(const InitialState()));
    await tester.pump();
    expect(find.byType(SkeletonCard), findsWidgets);

    await tester.pumpWidget(harness(const LoadingState()));
    await tester.pump();
    expect(find.byType(SkeletonCard), findsWidgets);
  });

  testWidgets('success renders the items', (tester) async {
    await tester.pumpWidget(harness(const SuccessState(['alpha', 'beta'])));
    await tester.pump();

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(find.byType(SkeletonCard), findsNothing);
  });

  testWidgets('empty renders the empty view', (tester) async {
    await tester.pumpWidget(harness(const EmptyState()));
    await tester.pump();

    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('error with no prior data takes over the screen', (tester) async {
    await tester.pumpWidget(harness(const ErrorState(ServerFailure('Boom'))));
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Boom'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });

  testWidgets('error over existing data shows an inline strip instead', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const ErrorState(ServerFailure('Boom'), previous: ['alpha'])),
    );
    await tester.pump();

    expect(find.text('alpha'), findsOneWidget, reason: 'data stays visible');
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('a stale success is labelled', (tester) async {
    await tester.pumpWidget(
      harness(
        SuccessState(
          const ['alpha'],
          isStale: true,
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Saved copy from'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
  });

  testWidgets('retry is wired to the refresh callback', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      harness(
        const ErrorState(ServerFailure('Boom')),
        onRefresh: () async => calls++,
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Try again'));
    await tester.pump();

    expect(calls, 1);
  });
}
