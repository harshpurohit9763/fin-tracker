import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/expense_model.dart';
import 'package:personal_finance/views/badge_model.dart';
import 'package:personal_finance/views/badge_provider.dart';
import 'package:personal_finance/views/goal_model.dart';
import 'package:personal_finance/views/goal_repo.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final goalListProvider =
    StateNotifierProvider<GoalListNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalListNotifier(ref);
});

class GoalListNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final Ref _ref;
  late final GoalRepository _repository;

  GoalListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(goalRepositoryProvider);
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await _repository.addGoal(goal);
      await _fetchGoals();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);
      await _fetchGoals();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _repository.deleteGoal(id);
      await _fetchGoals();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<bool> contributeToGoal(Goal goal, double amount) async {
    try {
      final wasCompletedBefore = goal.isCompleted;

      // 1. Update the goal's current amount in the database
      await _repository.contributeToGoal(goal.id!, amount);

      // 2. Add a corresponding expense transaction
      final expense = Expense(
        amount: amount,
        category: 'Goal Savings', // Specific category for goal contributions
        date: DateTime.now(),
        monthYear: AppFormatters.formatMonthYear(DateTime.now()),
        description: 'Contribution to "${goal.name}"',
        transactionType: 'Investment', // Classify as an investment
      );
      await _ref.read(expenseListProvider.notifier).addExpense(expense);

      // 3. Refresh the goal list to reflect the change
      await _fetchGoals();

      // 4. Check for completion and award badge
      final updatedGoal = state.value?.firstWhere((g) => g.id == goal.id,
          orElse: () =>
              goal.copyWith(currentAmount: goal.currentAmount + amount));

      if (updatedGoal != null &&
          updatedGoal.isCompleted &&
          !wasCompletedBefore) {
        final newBadge = Badge(
          goalName: updatedGoal.name,
          goalIcon: updatedGoal.icon,
          targetAmount: updatedGoal.targetAmount,
          completionDate: DateTime.now(),
        );
        await _ref.read(badgeListProvider.notifier).addBadge(newBadge);
        return true; // Goal was just completed
      }
      return false; // Goal not completed or was already complete
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}
