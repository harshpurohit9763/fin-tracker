import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/category_model.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/models/expense_tracker_model.dart';

// Provides the list of all categories
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>(
        (ref) {
  return CategoryListNotifier(ref);
});

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref _ref;
  late final ExpenseRepository _repository;

  CategoryListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(expenseRepositoryProvider);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(Category category) async {
    await _repository.addCategory(category);
    await _fetchCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    await _fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
    await _fetchCategories();
  }

  Future<void> deleteMultipleCategories(List<int> ids) async {
    for (var id in ids) {
      await _repository.deleteCategory(id);
    }
    await _fetchCategories();
  }
}
