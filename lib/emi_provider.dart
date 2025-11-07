import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/emi_model.dart';
import 'package:offline_expense_tracker/emi_repo.dart';

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
    try {
      final updatedEmi = await _repository.markEmiAsPaid(emi);
      await _fetchEmis();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
