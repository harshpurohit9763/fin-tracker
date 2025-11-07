import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/category_model.dart';
import 'package:offline_expense_tracker/expense_model.dart';
import 'package:offline_expense_tracker/expense_tracker_model.dart';

// Provides the repository instance
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

// Provides the list of all categories
final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getAllCategories();
});

// Provides the list of all expenses
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Expense>>>((
  ref,
) {
  return ExpenseListNotifier(ref);
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
