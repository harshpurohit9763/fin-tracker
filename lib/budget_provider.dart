import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/budget_model.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/report_provider.dart';
import 'package:sqflite/sqflite.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> upsertBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.budgetsTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> getBudgetsForMonth(String monthYear) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.budgetsTable,
      where: '${DatabaseHelper.colBudgetMonthYear} = ?',
      whereArgs: [monthYear],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.budgetsTable,
      where: '${DatabaseHelper.colBudgetId} = ?',
      whereArgs: [id],
    );
  }
}

final budgetRepositoryProvider = Provider((ref) => BudgetRepository());

final budgetListProvider =
    FutureProvider.autoDispose<List<Budget>>((ref) async {
  final monthYear = AppFormatters.formatMonthYear(DateTime.now());
  return ref.watch(budgetRepositoryProvider).getBudgetsForMonth(monthYear);
});

final categorySpendingProvider = FutureProvider.autoDispose
    .family<double, String>((ref, categoryName) async {
  final reportRepo = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final allSpending =
      await reportRepo.getCategoryBreakdown(startOfMonth, endOfMonth);
  return allSpending[categoryName] ?? 0.0;
});

final overallBudgetProvider = FutureProvider.autoDispose((ref) async {
  final budgets = await ref.watch(budgetListProvider.future);
  if (budgets.isEmpty) {
    return {'total': 0.0, 'spent': 0.0};
  }

  final totalBudget =
      budgets.fold<double>(0.0, (sum, item) => sum + item.amount);

  // To calculate total spent, we can leverage the report repository
  final reportRepo = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final totalSpent =
      await reportRepo.getTotalForDateRange(startOfMonth, endOfMonth);

  return {'total': totalBudget, 'spent': totalSpent};
});
