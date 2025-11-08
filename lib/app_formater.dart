import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppFormatters {
  // Currency Formatter
  static String formatCurrency(double amount, String currency) {
    String abbreviation;
    switch (currency) {
      case 'USD':
        abbreviation = 'USD';
        break;
      case 'EUR':
        abbreviation = 'EUR';
        break;
      case 'GBP':
        abbreviation = 'GBP';
        break;
      case 'JPY':
        abbreviation = 'JPY';
        break;
      case 'INR':
        abbreviation = 'Rs';
        break;
      default:
        abbreviation = currency; // Fallback to currency code if not found
    }

    final numberFormat = NumberFormat.currency(
      locale: 'en_US', // Use a consistent locale for number formatting
      symbol: '', // No symbol, we'll add abbreviation manually
      decimalDigits: 2,
    );

    final formattedAmount = numberFormat.format(amount);
    return '$formattedAmount $abbreviation';
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
