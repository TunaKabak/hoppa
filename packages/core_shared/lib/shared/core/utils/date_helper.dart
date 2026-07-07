import 'package:intl/intl.dart';

class DateHelper {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  /// Format DateTime to date string
  /// Example: 2024-01-15 -> "15.01.2024"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format DateTime to time string
  /// Example: 14:30 -> "14:30"
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format DateTime to date and time string
  /// Example: 2024-01-15 14:30 -> "15.01.2024 14:30"
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Get relative time string
  /// Example: "2 hours ago", "Just now"
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return formatDate(date);
    }
  }

  /// Get Turkish day name
  static String getTurkishDayName(DateTime date) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[date.weekday - 1];
  }

  /// Get Turkish month name
  static String getTurkishMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }
}
