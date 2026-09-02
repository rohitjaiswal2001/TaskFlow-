import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';

class FailureDisplay {
  const FailureDisplay({
    required this.icon,
    required this.title,
    required this.message,
    this.canRetry = true,
  });

  factory FailureDisplay.of(Failure failure) {
    return switch (failure) {
      OfflineFailure() => FailureDisplay(
        icon: Icons.cloud_off_rounded,
        title: 'You are offline',
        message: failure.message,
      ),
      TimeoutFailure() => FailureDisplay(
        icon: Icons.timer_off_outlined,
        title: 'That took too long',
        message: failure.message,
      ),
      NotFoundFailure() => FailureDisplay(
        icon: Icons.search_off_rounded,
        title: 'Not found',
        message: failure.message,
        canRetry: false,
      ),
      PermissionFailure() => FailureDisplay(
        icon: Icons.lock_outline_rounded,
        title: 'Not allowed',
        message: failure.message,
        canRetry: false,
      ),
      UnauthorizedFailure() => FailureDisplay(
        icon: Icons.person_off_outlined,
        title: 'Session ended',
        message: failure.message,
        canRetry: false,
      ),
      ValidationFailure() => FailureDisplay(
        icon: Icons.error_outline_rounded,
        title: 'Check the details',
        message: failure.message,
        canRetry: false,
      ),
      CacheFailure() => FailureDisplay(
        icon: Icons.inventory_2_outlined,
        title: 'Nothing saved yet',
        message: failure.message,
      ),
      CancelledFailure() => FailureDisplay(
        icon: Icons.cancel_outlined,
        title: 'Cancelled',
        message: failure.message,
        canRetry: false,
      ),
      ServerFailure() || UnexpectedFailure() => FailureDisplay(
        icon: Icons.report_gmailerrorred_rounded,
        title: 'Something went wrong',
        message: failure.message,
      ),
    };
  }

  final IconData icon;
  final String title;
  final String message;
  final bool canRetry;
}
