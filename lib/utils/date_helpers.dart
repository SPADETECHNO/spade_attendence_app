import 'package:intl/intl.dart';

class DateHelpers {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String timeString) {
    try {
      return DateFormat('HH:mm').parse(timeString);
    } catch (e) {
      return null;
    }
  }

  static String getFormattedDateRange(DateTime startDate, DateTime endDate) {
    if (isSameDay(startDate, endDate)) {
      return formatDate(startDate);
    }
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
}
