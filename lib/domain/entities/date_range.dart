import 'package:equatable/equatable.dart';

class DateRange extends Equatable {
  const DateRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => from == null && to == null;

  bool contains(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    final start = from;
    final end = to;
    if (start != null && day.isBefore(_day(start))) return false;
    if (end != null && day.isAfter(_day(end))) return false;
    return true;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [from, to];
}
