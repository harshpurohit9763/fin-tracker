import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/asset_provider.dart';
import 'package:offline_expense_tracker/budget_provider.dart';
import 'package:offline_expense_tracker/category_pie_chart.dart';
import 'package:offline_expense_tracker/insights_provider.dart';
import 'package:offline_expense_tracker/report_provider.dart';
import 'package:offline_expense_tracker/report_exporter.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';
import 'package:offline_expense_tracker/subscription_provider.dart';

import 'expense_model.dart';

/// Main screen for displaying advanced, filterable reports.
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  Future<void> _selectCustomDateRange(
      BuildContext context, WidgetRef ref) async {
    final initialRange = ref.read(currentDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(reportDateRangeTypeProvider.notifier).state =
          ReportDateRangeType.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Report',
            onPressed: () async {
              // Show a loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating report...')),
              );

              // Gather all the data needed for the report
              final dateRange = ref.read(currentDateRangeProvider);
              final userName = ref.read(userNameProvider);
              final currency = ref.read(currencyProvider);
              final expenses = await ref.read(filteredExpensesProvider.future)
                  as List<Expense>;
              final spendingBreakdown =
                  await ref.read(spendingBreakdownProvider.future);
              // Correctly read the data from StateNotifierProviders
              final assets = ref.read(assetListProvider).value ?? [];
              final subscriptions =
                  ref.read(subscriptionListProvider).value ?? [];

              final budgetData = await ref.read(overallBudgetProvider.future);

              await ReportExporter.generateAndShareReport(
                dateRange: dateRange,
                userName: userName,
                currency: currency,
                expenses: expenses,
                spendingBreakdown: spendingBreakdown,
                assets: assets,
                subscriptions: subscriptions,
                budgetData: budgetData,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _FilterBar(),
          SizedBox(height: 24),
          _IncomeVsExpenseCard(),
          SizedBox(height: 24),
          _AssetsSummaryCard(),
          SizedBox(height: 24),
          _RecurringCostsCard(),
          SizedBox(height: 24),
          _BudgetSummaryCard(),
          SizedBox(height: 24),
          _CategoryBreakdownCard(),
          SizedBox(height: 24),
          _TransactionListCard(),
        ],
      ),
    );
  }
}

/// A bar with dropdowns to filter all reports on the screen.
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  Future<void> _selectCustomDateRange(
      BuildContext context, WidgetRef ref) async {
    final initialRange = ref.read(currentDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(reportDateRangeTypeProvider.notifier).state =
          ReportDateRangeType.custom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeType = ref.watch(reportDateRangeTypeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Date Range and Account Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportDateRangeType>(
                    value: rangeType,
                    onChanged: (newValue) {
                      if (newValue == ReportDateRangeType.custom) {
                        _selectCustomDateRange(context, ref);
                      } else {
                        ref.read(reportDateRangeTypeProvider.notifier).state =
                            newValue!;
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                          value: ReportDateRangeType.thisMonth,
                          child: Text('This Month')),
                      DropdownMenuItem(
                          value: ReportDateRangeType.last7Days,
                          child: Text('Last 7 Days')),
                      DropdownMenuItem(
                          value: ReportDateRangeType.last30Days,
                          child: Text('Last 30 Days')),
                      DropdownMenuItem(
                          value: ReportDateRangeType.custom,
                          child: Text('Custom Range...')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Report Period',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for Income vs. Expense trend chart.
class _IncomeVsExpenseCard extends ConsumerWidget {
  const _IncomeVsExpenseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(spendingBreakdownProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs. Expense',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            breakdownAsync.when(
              data: (data) {
                final totalExpenses = data.needs + data.wants;
                final netFlow = data.investments - totalExpenses;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(
                        context,
                        'Total Expenses (Needs + Wants)',
                        AppFormatters.formatCurrency(totalExpenses, currency),
                        Colors.red),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        context,
                        'Total Savings (Investments)',
                        AppFormatters.formatCurrency(
                            data.investments, currency),
                        Colors.green),
                    const Divider(height: 24),
                    Text('Net Cash Flow',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatCurrency(netFlow, currency),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: netFlow >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

/// Card for Asset Summary.
class _AssetsSummaryCard extends ConsumerWidget {
  const _AssetsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset Summary',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) return const Text('No assets added.');
                final total =
                    assets.fold<double>(0, (prev, asset) => prev + asset.value);
                return Column(
                  children: [
                    ...assets.map((asset) => ListTile(
                          title: Text(asset.name),
                          trailing: Text(AppFormatters.formatCurrency(
                              asset.value, currency)),
                        )),
                    const Divider(),
                    ListTile(
                      title: const Text('Total Assets',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                          AppFormatters.formatCurrency(total, currency),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for Expense Category Breakdown donut chart.
class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Breakdown',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const SizedBox(height: 300, child: CategoryPieChartWidget()),
          ],
        ),
      ),
    );
  }
}

/// Card for Recurring Costs.
class _RecurringCostsCard extends ConsumerWidget {
  const _RecurringCostsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionListProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recurring Costs (Monthly)',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            subsAsync.when(
              data: (subs) {
                if (subs.isEmpty) return const Text('No subscriptions added.');
                final total =
                    subs.fold<double>(0, (prev, sub) => prev + sub.amount);
                return Column(
                  children: [
                    ...subs.map((sub) => ListTile(
                          title: Text(sub.name),
                          trailing: Text(AppFormatters.formatCurrency(
                              sub.amount, currency)),
                        )),
                    const Divider(),
                    ListTile(
                      title: const Text('Total Monthly Cost',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                          AppFormatters.formatCurrency(total, currency),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for Budget Summary.
class _BudgetSummaryCard extends ConsumerWidget {
  const _BudgetSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallBudgetAsync = ref.watch(overallBudgetProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Performance (This Month)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            overallBudgetAsync.when(
              data: (data) {
                final spent = data['spent']!;
                final total = data['total']!;
                if (total == 0) return const Text('No budgets set.');
                final percentage = total > 0 ? spent / total : 0.0;
                return Column(
                  children: [
                    LinearProgressIndicator(value: percentage, minHeight: 10),
                    const SizedBox(height: 8),
                    Text(
                        '${AppFormatters.formatCurrency(spent, currency)} of ${AppFormatters.formatCurrency(total, currency)}'),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying a detailed list of transactions.
class _TransactionListCard extends ConsumerWidget {
  const _TransactionListCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const SizedBox(
                      height: 100,
                      child: Center(
                          child: Text('No transactions in this period.')));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Amount'), numeric: true),
                    ],
                    rows: expenses.map((expense) {
                      return DataRow(cells: [
                        DataCell(Text(AppFormatters.formatDate(expense.date))),
                        DataCell(Text(expense.category)),
                        DataCell(Text(expense.description ?? '')),
                        DataCell(Text(AppFormatters.formatCurrency(
                            expense.amount, currency))),
                      ]);
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
