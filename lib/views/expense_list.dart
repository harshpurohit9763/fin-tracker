import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/widgets/add_expense.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart'
    hide selectedMonthYearProvider;
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final expensesAsyncValue = ref.watch(filteredExpenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          // Month Dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<int>(
              value: ref.watch(selectedMonthYearProvider).month,
              items: List.generate(12, (index) => index + 1).map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(AppFormatters.getMonthName(month)),
                );
              }).toList(),
              onChanged: (month) {
                if (month != null) {
                  final currentSelection = ref.read(selectedMonthYearProvider);
                  ref.read(selectedMonthYearProvider.notifier).state =
                      DateTime(currentSelection.year, month);
                }
              },
              underline: Container(),
            ),
          ),
          const SizedBox(width: 10),
          // Year Dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<int>(
              value: ref.watch(selectedMonthYearProvider).year,
              items: List.generate(
                6, // Current year and 5 previous years
                (index) => DateTime.now().year - index,
              ).map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (year) {
                if (year != null) {
                  final currentSelection = ref.read(selectedMonthYearProvider);
                  ref.read(selectedMonthYearProvider.notifier).state =
                      DateTime(year, currentSelection.month);
                }
              },
              underline: Container(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
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
              return ExpenseListItem(
                expense: expense,
                currency: currency,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(expense: expense),
                    ),
                  );
                },
                onDelete: () => _confirmDelete(context, ref, expense.id!),
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
