import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _timeFormat = DateFormat('HH:mm:ss');
  static final _shortDateTime = DateFormat('MMM d, HH:mm');
  static final _chartHourFormat = DateFormat('HH:mm');
  static final _chartDayFormat = DateFormat('MM/dd');

  static String formatTime(DateTime? date) {
    if (date == null) return '--:--:--';
    return _timeFormat.format(date);
  }

  static String formatShortDateTime(DateTime? date) {
    if (date == null) return 'Never';
    return _shortDateTime.format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return 'No timestamp';
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String formatForChart(DateTime date, Duration rangeDuration) {
    if (rangeDuration.inHours <= 24) {
      return _chartHourFormat.format(date);
    }
    return _chartDayFormat.format(date);
  }
}
