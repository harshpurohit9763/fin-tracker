import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/add_expense.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final expensesAsyncValue = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Expenses')),
      body: expensesAsyncValue.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'No expenses recorded yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(expense.category[0])),
                  title: Text(
                    AppFormatters.formatCurrency(expense.amount, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${expense.category} on ${AppFormatters.formatDate(expense.date)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, expense.id!),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddExpenseScreen(expense: expense),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
}
