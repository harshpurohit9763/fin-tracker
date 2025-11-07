import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/db_helper.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get total spending for a given date range
  Future<double> getTotalForDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    // Ensure the end of the day is included in the query
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseHelper.colAmount}) as total FROM ${DatabaseHelper.expensesTable} WHERE ${DatabaseHelper.colDate} >= ? AND ${DatabaseHelper.colDate} <= ?',
      [start.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Get spending for last 6 months (for dashboard)
  Future<Map<String, double>> getLast6MonthsSpending() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    Map<String, double> monthlyTotals = {};

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final endOfMonth = DateTime(now.year, now.month - i + 1, 0);
      final monthYear = AppFormatters.formatMonthYear(date);
      final total = await getTotalForDateRange(date, endOfMonth);
      monthlyTotals[monthYear] = total;
    }
    return monthlyTotals;
  }

  // Get category breakdown for a specific date range
  Future<Map<String, double>> getCategoryBreakdown(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    // Ensure the end of the day is included in the query
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.expensesTable,
      columns: [
        DatabaseHelper.colCategory,
        'SUM(${DatabaseHelper.colAmount}) as total',
      ],
      where:
          '${DatabaseHelper.colDate} >= ? AND ${DatabaseHelper.colDate} <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      groupBy: DatabaseHelper.colCategory,
    );

    return {
      for (var map in maps)
        map[DatabaseHelper.colCategory]: (map['total'] as num).toDouble(),
    };
  }

  // Get daily spending trend for a specific date range
  Future<Map<DateTime, double>> getDailySpending(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT date(${DatabaseHelper.colDate} / 1000, 'unixepoch') as expense_date, SUM(${DatabaseHelper.colAmount}) as total "
      "FROM ${DatabaseHelper.expensesTable} "
      "WHERE ${DatabaseHelper.colDate} >= ? AND ${DatabaseHelper.colDate} <= ? "
      "GROUP BY expense_date "
      "ORDER BY expense_date",
      [start.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    return {
      for (var map in maps)
        DateTime.parse(map['expense_date'] as String):
            (map['total'] as num).toDouble(),
    };
  }
}
