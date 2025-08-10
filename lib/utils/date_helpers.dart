import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateHelpers {
  // **ENHANCED: More flexible date formatting**
  static String formatDate(DateTime date, {String? pattern}) {
    pattern ??= 'yyyy-MM-dd';
    return DateFormat(pattern).format(date);
  }

  static String formatTime(DateTime time, {bool use24Hour = true}) {
    String pattern = use24Hour ? 'HH:mm' : 'hh:mm a';
    return DateFormat(pattern).format(time);
  }

  static String formatDateTime(DateTime dateTime, {String? pattern}) {
    pattern ??= 'yyyy-MM-dd HH:mm:ss';
    return DateFormat(pattern).format(dateTime);
  }

  // **NEW: Year-specific formatting for Firebase structure**
  static String getYearFromDate(DateTime date) {
    return date.year.toString();
  }

  static String formatDateWithYear(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  // **NEW: User-friendly date formatting**
  static String formatDateForDisplay(DateTime date) {
    DateTime now = DateTime.now();
    
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, now.subtract(Duration(days: 1)))) {
      return 'Yesterday';
    } else if (isSameDay(date, now.add(Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (date.year == now.year) {
      return DateFormat('dd MMM').format(date); // "15 Jan"
    } else {
      return DateFormat('dd MMM yyyy').format(date); // "15 Jan 2024"
    }
  }

  // **NEW: Time formatting with context**
  static String formatTimeForDisplay(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static DateTime? parseDate(String dateString, {String? pattern}) {
    try {
      pattern ??= 'yyyy-MM-dd';
      return DateFormat(pattern).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String timeString, {String? pattern}) {
    try {
      pattern ??= 'HH:mm';
      return DateFormat(pattern).parse(timeString);
    } catch (e) {
      return null;
    }
  }

  // **ENHANCED: More flexible date range formatting**
  static String getFormattedDateRange(DateTime startDate, DateTime endDate, {bool includeYear = true}) {
    if (isSameDay(startDate, endDate)) {
      return includeYear ? formatDateWithYear(startDate) : formatDate(startDate, pattern: 'dd MMM');
    }
    
    if (startDate.year == endDate.year) {
      if (includeYear) {
        return '${formatDate(startDate, pattern: 'dd MMM')} - ${formatDateWithYear(endDate)}';
      } else {
        return '${formatDate(startDate, pattern: 'dd MMM')} - ${formatDate(endDate, pattern: 'dd MMM')}';
      }
    }
    
    return '${formatDateWithYear(startDate)} - ${formatDateWithYear(endDate)}';
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // **NEW: Year-based comparison methods**
  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  static bool isCurrentYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static bool isCurrentMonth(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // **NEW: Time period calculations**
  static int daysBetween(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays;
  }

  static int yearsBetween(DateTime startDate, DateTime endDate) {
    return endDate.year - startDate.year;
  }

  static bool isWithinTimeRange(DateTime dateTime, String startTime, String endTime) {
    DateTime? start = parseTime(startTime);
    DateTime? end = parseTime(endTime);
    
    if (start == null || end == null) return false;
    
    TimeOfDay currentTime = TimeOfDay.fromDateTime(dateTime);
    TimeOfDay startTimeOfDay = TimeOfDay.fromDateTime(start);
    TimeOfDay endTimeOfDay = TimeOfDay.fromDateTime(end);
    
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;
    int startMinutes = startTimeOfDay.hour * 60 + startTimeOfDay.minute;
    int endMinutes = endTimeOfDay.hour * 60 + endTimeOfDay.minute;
    
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // **NEW: Get available years from date list**
  static List<String> getAvailableYears(List<DateTime> dates) {
    Set<String> years = dates.map((date) => getYearFromDate(date)).toSet();
    List<String> sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    return sortedYears;
  }

  // **NEW: Filter dates by year**
  static List<DateTime> filterDatesByYear(List<DateTime> dates, String year) {
    return dates.where((date) => getYearFromDate(date) == year).toList();
  }

  // **NEW: Session time helpers**
  static String getSessionDuration(String startTime, String endTime) {
    DateTime? start = parseTime(startTime);
    DateTime? end = parseTime(endTime);
    
    if (start == null || end == null) return 'Invalid time';
    
    Duration duration = end.difference(start);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  // **NEW: Relative time formatting**
  static String getRelativeTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      int years = (difference.inDays / 365).floor();
      return '${years} year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      int months = (difference.inDays / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // **NEW: Week boundaries**
  static DateTime getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  static DateTime getEndOfWeek(DateTime date) {
    int daysToAdd = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day).add(Duration(days: daysToAdd));
  }

  // **NEW: Month boundaries**
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // **NEW: Year boundaries**
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  // **NEW: Validation helpers**
  static bool isValidDateRange(DateTime startDate, DateTime endDate) {
    return startDate.isBefore(endDate) || isSameDay(startDate, endDate);
  }

  static bool isValidTimeRange(String startTime, String endTime) {
    DateTime? start = parseTime(startTime);
    DateTime? end = parseTime(endTime);
    
    if (start == null || end == null) return false;
    
    return start.isBefore(end);
  }

  // **NEW: Firebase Timestamp helpers**
  static DateTime fromTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is DateTime) return timestamp;
    
    // Handle Firestore Timestamp
    if (timestamp.runtimeType.toString().contains('Timestamp')) {
      return timestamp.toDate();
    }
    
    return DateTime.now();
  }

  // **NEW: Attendance-specific helpers**
  static String formatAttendanceDate(DateTime date) {
    if (isToday(date)) {
      return 'Today, ${formatTime(date, use24Hour: false)}';
    } else if (isSameDay(date, DateTime.now().subtract(Duration(days: 1)))) {
      return 'Yesterday, ${formatTime(date, use24Hour: false)}';
    } else if (isCurrentYear(date)) {
      return '${formatDate(date, pattern: 'dd MMM')}, ${formatTime(date, use24Hour: false)}';
    } else {
      return '${formatDateWithYear(date)}, ${formatTime(date, use24Hour: false)}';
    }
  }

  // **NEW: Session status helpers**
  static String getSessionStatus(DateTime sessionDate, String startTime, String endTime) {
    DateTime now = DateTime.now();
    
    if (!isSameDay(sessionDate, now)) {
      if (sessionDate.isBefore(now)) {
        return 'Completed';
      } else {
        return 'Scheduled';
      }
    }
    
    if (isWithinTimeRange(now, startTime, endTime)) {
      return 'Active';
    } else {
      DateTime? start = parseTime(startTime);
      if (start != null) {
        TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
        TimeOfDay sessionStart = TimeOfDay.fromDateTime(start);
        
        int currentMinutes = currentTime.hour * 60 + currentTime.minute;
        int startMinutes = sessionStart.hour * 60 + sessionStart.minute;
        
        if (currentMinutes < startMinutes) {
          return 'Upcoming';
        } else {
          return 'Ended';
        }
      }
    }
    
    return 'Unknown';
  }
}
