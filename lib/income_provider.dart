import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/income_model.dart';
import 'package:personal_finance/selected_month_year_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_finance/shared_preferences_provider.dart';
import 'package:personal_finance/shared_preferences_provider.dart'; // Assuming this provider exists

// 1. IncomeRepository to handle database operations
class IncomeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addIncome(Income income) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.incomeTable, income.toMap());
  }

  Future<int> updateIncome(Income income) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.incomeTable,
      income.toMap(),
      where: '${DatabaseHelper.colIncomeId} = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.incomeTable,
      where: '${DatabaseHelper.colIncomeId} = ?',
      whereArgs: [id],
    );
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.incomeTable,
      orderBy: '${DatabaseHelper.colIncomeDate} DESC',
    );
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<List<Income>> getIncomesByMonthYear(String monthYear) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.incomeTable,
      where: '${DatabaseHelper.colIncomeMonthYear} = ?',
      whereArgs: [monthYear],
      orderBy: '${DatabaseHelper.colIncomeDate} DESC',
    );
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }
}

// 2. IncomeListNotifier to manage the state of income list
class IncomeListNotifier extends StateNotifier<AsyncValue<List<Income>>> {
  final IncomeRepository _repository;

  IncomeListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    try {
      final incomes = await _repository.getAllIncomes();
      state = AsyncValue.data(incomes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addIncome(Income income) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addIncome(income);
      await _loadIncomes(); // Reload all incomes after adding
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateIncome(Income income) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateIncome(income);
      await _loadIncomes(); // Reload all incomes after updating
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteIncome(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteIncome(id);
      await _loadIncomes(); // Reload all incomes after deleting
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 3. Provider for incomeListProvider
final incomeRepositoryProvider = Provider((ref) => IncomeRepository());

final incomeListProvider =
    StateNotifierProvider<IncomeListNotifier, AsyncValue<List<Income>>>((ref) {
  return IncomeListNotifier(ref.watch(incomeRepositoryProvider));
});

final filteredIncomeListProvider =
    Provider.autoDispose<AsyncValue<List<Income>>>((ref) {
  final incomesAsyncValue = ref.watch(incomeListProvider);
  final selectedMonthYear =
      ref.watch(selectedMonthYearProvider); // Assuming this provider exists

  return incomesAsyncValue.when(
    data: (incomes) {
      final filteredIncomes = incomes.where((income) {
        return income.monthYear ==
            '${selectedMonthYear.year}-${selectedMonthYear.month.toString().padLeft(2, '0')}';
      }).toList();
      return AsyncValue.data(filteredIncomes);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});
