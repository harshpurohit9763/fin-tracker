import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/emi_model.dart';
import 'package:personal_finance/helper/emi_repo.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/controllers/expense_provider.dart';

// Provides the repository instance
final emiRepositoryProvider = Provider<EmiRepository>((ref) {
  return EmiRepository();
});

// Provides the list of all EMIs
final emiListProvider =
    StateNotifierProvider<EmiListNotifier, AsyncValue<List<Emi>>>((ref) {
  return EmiListNotifier(ref);
});

class EmiListNotifier extends StateNotifier<AsyncValue<List<Emi>>> {
  final Ref _ref;
  late final EmiRepository _repository;

  EmiListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(emiRepositoryProvider);
    _fetchEmis();
  }

  Future<void> _fetchEmis() async {
    state = const AsyncValue.loading();
    try {
      final emis = await _repository.getAllEmis();
      state = AsyncValue.data(emis);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addEmi(Emi emi) async {
    try {
      final id = await _repository.addEmi(emi);
      await _fetchEmis();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateEmi(Emi emi) async {
    try {
      await _repository.updateEmi(emi);
      await _fetchEmis();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteEmi(int id) async {
    try {
      await _repository.deleteEmi(id);
      // Since we no longer schedule far in advance, cancellation isn't strictly needed
      // as the background job just won't find the deleted EMI.
      // Keeping it is harmless if you want to be extra safe.
      // _notificationService.cancelNotification(id);
      await _fetchEmis();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> markEmiAsPaid(Emi emi) async {
    // This now calls the new method with the default amount.
    await markEmiAsPaidWithAmount(emi, emi.monthlyEmiAmount);
  }

  Future<void> markEmiAsPaidWithAmount(Emi emi, double paidAmount) async {
    try {
      // First, update the EMI tenure and next due date
      await _repository.markEmiAsPaid(emi);

      // Then, add an expense with the actual paid amount
      final now = DateTime.now();
      final expense = Expense(
        amount: paidAmount,
        category: 'EMI',
        date: now,
        monthYear: "${now.year}-${now.month.toString().padLeft(2, '0')}",
        description: "${emi.loanName} EMI Payment",
        scheduledAmount: emi.monthlyEmiAmount, // Store original amount
        transactionType: 'EMI', // Identify as an EMI transaction
      );
      await _ref.read(expenseListProvider.notifier).addExpense(expense);

      // Finally, refresh the EMI list to reflect changes
      await _fetchEmis();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
