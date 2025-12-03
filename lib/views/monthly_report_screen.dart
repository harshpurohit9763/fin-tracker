import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/widgets/month_year_selector.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart'
    hide selectedMonthYearProvider;
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/widgets/income_expense_chart.dart';
import 'package:intl/intl.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32), // Spacer for top
            Row(
              children: [
                CupertinoNavigationBarBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Monthly Report',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                )
              ],
            ),

            // Header with "Monthly Report" title and Month/Year selector

            const SizedBox(height: 16),
            MonthYearSelector(
                placement: SelectorPlacement.body), // Use the new widget
            const SizedBox(height: 32),

            // Income vs Expense Chart
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Income vs Expense',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: IncomeExpenseChart(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Income Section
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Income',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            incomesAsyncValue.when(
              data: (incomes) {
                if (incomes.isEmpty) {
                  return Text(
                    'No income for this month.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
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

            const SizedBox(height: 32),

            // Expense Section
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Expenses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            expensesAsyncValue.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Text(
                    'No expenses for this month.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ExpenseListItem(
                      expense: expense,
                      currency: currency,
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
