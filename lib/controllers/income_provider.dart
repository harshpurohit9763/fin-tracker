import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart';
// Assuming this provider exists

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
  final selectedMonthYear = ref.watch(
      selectedMonthYearProvider); // Provider of the currently viewed month as DateTime

  return incomesAsyncValue.when(
    data: (incomes) {
      // Correctly compare years and months for filtering
      final oneTimeIncomes = incomes.where((income) {
        return !income.isMonthly &&
            income.date.year == selectedMonthYear.year &&
            income.date.month == selectedMonthYear.month;
      }).toList();

      final recurringIncomes = incomes.where((income) {
        if (!income.isMonthly) return false;

        // Create DateTime objects for comparison, ignoring the day
        final incomeMonth = DateTime(income.date.year, income.date.month);
        final selectedMonth =
            DateTime(selectedMonthYear.year, selectedMonthYear.month);

        // A recurring income should appear if its start month is on or before the selected month
        return !incomeMonth.isAfter(selectedMonth);
      }).toList();

      final filteredIncomes = [...oneTimeIncomes, ...recurringIncomes];
      filteredIncomes.sort((a, b) => b.date.compareTo(a.date));

      return AsyncValue.data(filteredIncomes);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});
