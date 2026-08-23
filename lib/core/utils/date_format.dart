import 'package:intl/intl.dart';

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM yyyy');
final _timestamp = DateFormat('d MMM, HH:mm');
final _fullDate = DateFormat('EEEE, d MMMM yyyy');

extension DateOnlyX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

abstract final class Dates {
  static DateTime? tryParseDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String toDayString(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String formatDue(DateTime date, {DateTime? now}) {
    final today = (now ?? DateTime.now()).dateOnly;
    final target = date.dateOnly;
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return 'In $diff days';
    if (diff < -1 && diff > -7) return '${-diff} days ago';

    return target.year == today.year
        ? _dayMonth.format(target)
        : _dayMonthYear.format(target);
  }

  static String formatFull(DateTime date) => _fullDate.format(date);

  static String formatTimestamp(DateTime value) =>
      _timestamp.format(value.toLocal());

  static String relative(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dayMonthYear.format(value.toLocal());
  }
}
