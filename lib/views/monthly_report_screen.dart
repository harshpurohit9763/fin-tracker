import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/income_expense_chart.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonthYear = ref.watch(selectedMonthYearProvider);
    final currency = ref.watch(currencyProvider);
    final incomesAsyncValue = ref.watch(filteredIncomeListProvider);
    final expensesAsyncValue = ref.watch(filteredExpenseListProvider);

    final totalIncome = incomesAsyncValue.when(
      data: (incomes) => incomes.fold(0.0, (sum, item) => sum + item.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    final totalExpense = expensesAsyncValue.when(
      data: (expenses) => expenses.fold(0.0, (sum, item) => sum + item.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month/Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Month Dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButton<int>(
                    value: selectedMonthYear.month,
                    items: List.generate(12, (index) => index + 1).map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(AppFormatters.getMonthName(month)),
                      );
                    }).toList(),
                    onChanged: (month) {
                      if (month != null) {
                        ref.read(selectedMonthYearProvider.notifier).state =
                            DateTime(selectedMonthYear.year, month);
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButton<int>(
                    value: selectedMonthYear.year,
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
                        ref.read(selectedMonthYearProvider.notifier).state =
                            DateTime(year, selectedMonthYear.month);
                      }
                    },
                    underline: Container(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Income vs Expense Chart
            IncomeExpenseChart(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
            ),
            const SizedBox(height: 24),

            // Income Section
            Text(
              'Income',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            incomesAsyncValue.when(
              data: (incomes) {
                if (incomes.isEmpty) {
                  return const Text('No income for this month.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    return IncomeCard(income: income);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            const SizedBox(height: 24),

            // Expense Section
            Text(
              'Expenses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            expensesAsyncValue.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Text('No expenses for this month.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];

                    if (expense.transactionType == 'EMI' &&
                        expense.scheduledAmount != null) {
                      final difference =
                          expense.amount - expense.scheduledAmount!;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.description ?? 'EMI Payment',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paid on: ${AppFormatters.formatDate(expense.date)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Original EMI:'),
                                  Text(AppFormatters.formatCurrency(
                                      expense.scheduledAmount!, currency)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Amount Paid:'),
                                  Text(
                                    AppFormatters.formatCurrency(
                                        expense.amount, currency),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Difference:'),
                                  Text(
                                    AppFormatters.formatCurrency(
                                        difference, currency),
                                    style: TextStyle(
                                      color: difference == 0
                                          ? Colors.grey
                                          : difference > 0
                                              ? Colors.red
                                              : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Default view for other expenses
                    return Card(
                      child: ListTile(
                        title: Text(AppFormatters.formatCurrency(
                            expense.amount, currency)),
                        subtitle: Text(
                            '${expense.category} on ${AppFormatters.formatDate(expense.date)}'),
                        trailing: expense.description != null
                            ? Text(expense.description!)
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
