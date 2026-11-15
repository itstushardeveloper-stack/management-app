import 'package:intl/intl.dart';

class DateFormatters {
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDateShort = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _dayDate = DateFormat('EEE, dd MMM');
  static final DateFormat _time12 = DateFormat('h:mm a');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _displayDate.format(date);
  }

  static String formatDateShort(DateTime? date) {
    if (date == null) return '-';
    return _displayDateShort.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String formatDayDate(DateTime date) {
    return _dayDate.format(date);
  }

  static String formatTime(DateTime time) {
    return _time12.format(time);
  }

  static String formatIsoDate(DateTime date) {
    return _isoDate.format(date);
  }

  static DateTime? parseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

