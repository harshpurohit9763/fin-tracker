import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/widgets/add_expense.dart';
import 'package:personal_finance/widgets/month_year_selector.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart';
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final expensesAsyncValue = ref.watch(filteredExpenseListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('All Expenses'),
            floating: true,
            snap: true,
            actions: const [
              // Use the new widget in the AppBar
              MonthYearSelector(placement: SelectorPlacement.appBar),
              SizedBox(width: 10), // Maintain original spacing
            ],
          ),
          expensesAsyncValue.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No expenses recorded yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = expenses[index];
                    return ExpenseListItem(
                      expense: expense,
                      currency: currency,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddExpenseScreen(expense: expense),
                          ),
                        );
                      },
                      // onDelete: () => _confirmDelete(context, ref, expense.id!),
                    );
                  },
                  childCount: expenses.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              ref.read(expenseListProvider.notifier).deleteExpense(id);
              // Invalidate dashboard providers
              // ref.invalidate(dashboardMetricsProvider);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
