import 'package:flutter/material.dart';

import 'app_palette.dart';

@immutable
class AccentColors extends ThemeExtension<AccentColors> {
  const AccentColors({
    required this.todo,
    required this.inProgress,
    required this.review,
    required this.done,
    required this.priorityLow,
    required this.priorityMedium,
    required this.priorityHigh,
    required this.priorityUrgent,
    required this.overdue,
    required this.tintOpacity,
  });

  factory AccentColors.light() => const AccentColors(
    todo: AppPalette.slate,
    inProgress: AppPalette.blue,
    review: AppPalette.amber,
    done: AppPalette.green,
    priorityLow: AppPalette.slate,
    priorityMedium: AppPalette.blue,
    priorityHigh: AppPalette.orange,
    priorityUrgent: AppPalette.red,
    overdue: AppPalette.red,
    tintOpacity: 0.10,
  );

  factory AccentColors.dark() => const AccentColors(
    todo: Color(0xFF9AA3B2),
    inProgress: Color(0xFF6E9BFF),
    review: Color(0xFFE0A233),
    done: Color(0xFF41C07C),
    priorityLow: Color(0xFF9AA3B2),
    priorityMedium: Color(0xFF6E9BFF),
    priorityHigh: Color(0xFFFF9257),
    priorityUrgent: Color(0xFFFF6B7D),
    overdue: Color(0xFFFF6B7D),
    tintOpacity: 0.18,
  );

  final Color todo;
  final Color inProgress;
  final Color review;
  final Color done;
  final Color priorityLow;
  final Color priorityMedium;
  final Color priorityHigh;
  final Color priorityUrgent;
  final Color overdue;
  final double tintOpacity;

  @override
  AccentColors copyWith({
    Color? todo,
    Color? inProgress,
    Color? review,
    Color? done,
    Color? priorityLow,
    Color? priorityMedium,
    Color? priorityHigh,
    Color? priorityUrgent,
    Color? overdue,
    double? tintOpacity,
  }) {
    return AccentColors(
      todo: todo ?? this.todo,
      inProgress: inProgress ?? this.inProgress,
      review: review ?? this.review,
      done: done ?? this.done,
      priorityLow: priorityLow ?? this.priorityLow,
      priorityMedium: priorityMedium ?? this.priorityMedium,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityUrgent: priorityUrgent ?? this.priorityUrgent,
      overdue: overdue ?? this.overdue,
      tintOpacity: tintOpacity ?? this.tintOpacity,
    );
  }

  @override
  AccentColors lerp(ThemeExtension<AccentColors>? other, double t) {
    if (other is! AccentColors) return this;
    return AccentColors(
      todo: Color.lerp(todo, other.todo, t)!,
      inProgress: Color.lerp(inProgress, other.inProgress, t)!,
      review: Color.lerp(review, other.review, t)!,
      done: Color.lerp(done, other.done, t)!,
      priorityLow: Color.lerp(priorityLow, other.priorityLow, t)!,
      priorityMedium: Color.lerp(priorityMedium, other.priorityMedium, t)!,
      priorityHigh: Color.lerp(priorityHigh, other.priorityHigh, t)!,
      priorityUrgent: Color.lerp(priorityUrgent, other.priorityUrgent, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      tintOpacity: tintOpacity + (other.tintOpacity - tintOpacity) * t,
    );
  }
}

extension AccentColorsX on BuildContext {
  AccentColors get accents => Theme.of(this).extension<AccentColors>()!;
}
