import 'package:intl/intl.dart';

class AppFormatters {
  // Currency Formatter
  static String formatCurrency(double amount, String currency) {
    final format = NumberFormat.simpleCurrency(
      locale: 'en_US', // You can customize this further if needed
      name: currency,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Date Formatter (e.g., Nov 7, 2025)
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  // Date Formatter for Database (e.g., 2025-11)
  static String formatMonthYear(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // Timestamp to DateTime
  static DateTime timestampToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // DateTime to Timestamp
  static int dateTimeToTimestamp(DateTime date) {
    return date.millisecondsSinceEpoch;
  }

  // Get month name from month number (1-12)
  static String getMonthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) {
      throw ArgumentError('Month number must be between 1 and 12');
    }
    return DateFormat.MMMM().format(DateTime(2000, monthNumber));
  }
}
