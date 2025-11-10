import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/models/expense_model.dart'; // Import Expense model

class CashFlowData {
  final int month;
  final int year;
  final double income;
  final double expenses;

  CashFlowData({
    required this.month,
    required this.year,
    required this.income,
    required this.expenses,
  });

  double get netFlow => income - expenses;
}

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all incomes
  Future<List<Income>> getAllIncomes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseHelper.incomeTable);
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  // Get paginated expenses for a given date range
  Future<List<Expense>> getExpensesPaginated(
      DateTime start, DateTime end, int limit, int offset) async {
    final db = await _dbHelper.database;
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.expensesTable,
      where:
          '${DatabaseHelper.colDate} >= ? AND ${DatabaseHelper.colDate} <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: '${DatabaseHelper.colDate} DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // Get paginated incomes for a given date range
  Future<List<Income>> getIncomesPaginated(
      DateTime start, DateTime end, int limit, int offset) async {
    final db = await _dbHelper.database;
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.incomeTable,
      where:
          '${DatabaseHelper.colIncomeDate} >= ? AND ${DatabaseHelper.colIncomeDate} <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: '${DatabaseHelper.colIncomeDate} DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  // Get total income for a given date range
  Future<double> getTotalIncomeForDateRange(
      DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseHelper.colIncomeAmount}) as total FROM ${DatabaseHelper.incomeTable} WHERE ${DatabaseHelper.colIncomeDate} >= ? AND ${DatabaseHelper.colIncomeDate} <= ?',
      [start.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

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

  // Get monthly spending for a given date range
  Future<Map<String, double>> getMonthlySpendingForRange(
      DateTime start, DateTime end) async {
    Map<String, double> monthlyTotals = {};

    DateTime currentMonth = DateTime(start.year, start.month, 1);
    while (currentMonth.isBefore(end) ||
        currentMonth.isAtSameMomentAs(DateTime(end.year, end.month, 1))) {
      final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      final monthYear = AppFormatters.formatMonthYear(currentMonth);
      final total = await getTotalForDateRange(currentMonth, endOfMonth);
      monthlyTotals[monthYear] = total;

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    return monthlyTotals;
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

  Future<List<CashFlowData>> getMonthlyCashFlow(
      DateTime start, DateTime end) async {
    List<CashFlowData> cashFlows = [];
    DateTime currentMonth = DateTime(start.year, start.month, 1);

    while (currentMonth.isBefore(end) ||
        currentMonth.isAtSameMomentAs(DateTime(end.year, end.month, 1))) {
      final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);

      final income = await getTotalIncomeForDateRange(currentMonth, endOfMonth);
      final expenses = await getTotalForDateRange(currentMonth, endOfMonth);

      cashFlows.add(CashFlowData(
        month: currentMonth.month,
        year: currentMonth.year,
        income: income,
        expenses: expenses,
      ));

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    return cashFlows;
  }
}
