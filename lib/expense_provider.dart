import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/expense_model.dart';
import 'package:personal_finance/expense_tracker_model.dart';

// Provides the repository instance
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(); // Assuming ExpenseRepository is defined in expense_repo.dart
});

// Provides the list of all expenses
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Expense>>>((
  ref,
) {
  return ExpenseListNotifier(ref);
});

// Provides the currently selected month and year for filtering expenses
final selectedMonthYearProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month); // Default to current month and year
});

// Provides a filtered list of expenses based on the selected month and year
final filteredExpenseListProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final allExpensesAsync = ref.watch(expenseListProvider);
  final selectedMonthYear = ref.watch(selectedMonthYearProvider);

  return allExpensesAsync.when(
    data: (allExpenses) {
      return allExpenses.where((expense) {
        return expense.date.year == selectedMonthYear.year &&
            expense.date.month == selectedMonthYear.month;
      }).toList();
    },
    loading: () => [], // Return an empty list while loading
    error: (e, s) => throw e, // Propagate the error
  );
});

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref _ref;
  late final ExpenseRepository _repository;

  ExpenseListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(expenseRepositoryProvider);
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      await _fetchExpenses();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);
      await _fetchExpenses();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await _fetchExpenses();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
