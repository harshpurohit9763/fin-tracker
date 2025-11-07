import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/db_helper.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get total spending for current month
  Future<double> getTotalForMonth(String monthYear) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseHelper.colAmount}) as total FROM ${DatabaseHelper.expensesTable} WHERE ${DatabaseHelper.colMonthYear} = ?',
      [monthYear],
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
      final monthYear = AppFormatters.formatMonthYear(date);
      final total = await getTotalForMonth(monthYear);
      monthlyTotals[monthYear] = total;
    }
    return monthlyTotals;
  }

  // Get category breakdown for a specific month
  Future<Map<String, double>> getCategoryBreakdown(String monthYear) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.expensesTable,
      columns: [
        DatabaseHelper.colCategory,
        'SUM(${DatabaseHelper.colAmount}) as total',
      ],
      where: '${DatabaseHelper.colMonthYear} = ?',
      whereArgs: [monthYear],
      groupBy: DatabaseHelper.colCategory,
    );

    return {
      for (var map in maps)
        map[DatabaseHelper.colCategory]: (map['total'] as num).toDouble(),
    };
  }

  // Get weekly spending trend for a specific month
  Future<Map<int, double>> getWeeklySpending(String monthYear) async {
    final db = await _dbHelper.database;
    // 'unixepoch' works with the integer timestamp
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT strftime('%W', ${DatabaseHelper.colDate} / 1000, 'unixepoch') as week, SUM(${DatabaseHelper.colAmount}) as total "
      "FROM ${DatabaseHelper.expensesTable} "
      "WHERE ${DatabaseHelper.colMonthYear} = ? "
      "GROUP BY week "
      "ORDER BY week",
      [monthYear],
    );

    return {
      for (var map in maps)
        int.parse(map['week'] as String): (map['total'] as num).toDouble(),
    };
  }
}
