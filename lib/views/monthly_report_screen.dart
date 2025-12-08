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

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Data Fetching
    final currency = ref.watch(currencyProvider);
    final incomesAsyncValue = ref.watch(filteredIncomeListProvider);
    final expensesAsyncValue = ref.watch(filteredExpenseListProvider);

    // Theme Data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);

    // Calculations
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

    final netSavings = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Financial Report',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Month Selector
            const Center(
              child: MonthYearSelector(placement: SelectorPlacement.body),
            ),
            const SizedBox(height: 24),

            // 2. Net Savings Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Net Savings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.formatCurrency(netSavings, currency),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(context,
                            label: 'Income',
                            amount: totalIncome,
                            color: Colors.greenAccent.shade100,
                            icon: Icons.arrow_downward_rounded,
                            currency: currency),
                        Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2)),
                        _buildSummaryItem(context,
                            label: 'Expense',
                            amount: totalExpense,
                            color: Colors.redAccent.shade100,
                            icon: Icons.arrow_upward_rounded,
                            currency: currency),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: IncomeExpenseChart(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 4. Detailed Lists
            _buildSectionHeader(
                context, 'Income', Icons.wallet_giftcard_rounded),
            const SizedBox(height: 12),
            incomesAsyncValue.when(
              data: (incomes) {
                if (incomes.isEmpty)
                  return _buildEmptyState(context, 'No income records.');
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: incomes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      IncomeCard(income: incomes[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),

            const SizedBox(height: 32),

            _buildSectionHeader(
                context, 'Expenses', Icons.receipt_long_rounded),
            const SizedBox(height: 12),
            expensesAsyncValue.when(
              data: (expenses) {
                if (expenses.isEmpty)
                  return _buildEmptyState(context, 'No expense records.');
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => ExpenseListItem(
                    expense: expenses[index],
                    currency: currency,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Helper Widget for the Header Summary
  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required String currency,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(amount, currency),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // Helper for Empty States
  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
