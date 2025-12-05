import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/widgets/category_pie_chart.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/controllers/report_provider.dart';
import 'package:personal_finance/helper/report_exporter.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/subscription_provider.dart';

import '../models/expense_model.dart';

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
        automaticallyImplyLeading: false,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Advanced Reports'),
        centerTitle: true, // Center the title for better aesthetics
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
              final currency = ref.read(currencyProvider);
              final expenses =
                  await ref.read(allExpensesForReportProvider.future);
              final incomes =
                  await ref.read(allIncomesForReportProvider.future);
              final spendingBreakdown =
                  await ref.read(spendingBreakdownProvider.future);
              // Correctly read the data from StateNotifierProviders
              final assets = ref.read(assetListProvider).value ?? [];
              final subscriptions =
                  ref.read(subscriptionListProvider).value ?? [];

              final budgetData = await ref.read(overallBudgetProvider.future);

              await ReportExporter.generateAndShareReport(
                dateRange: dateRange,
                currency: currency,
                expenses: expenses,
                incomes: incomes,
                spendingBreakdown: spendingBreakdown,
                assets: assets,
                subscriptions: subscriptions,
                budgetData: budgetData,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints:
                const BoxConstraints(maxWidth: 600), // Equivalent to max-w-lg
            margin: const EdgeInsets.all(16.0), // Equivalent to mx-auto p-6
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(40.0), // rounded-[40px]
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'sans-serif', // font-sans
                      ),
                ),
                const SizedBox(height: 24), // mb-6
                const _FilterBar(),
                const SizedBox(height: 24),
                const _IncomeVsExpenseCard(),
                const SizedBox(height: 24),
                const _AssetsSummaryCard(),
                const SizedBox(height: 24),
                const _RecurringCostsCard(),
                const SizedBox(height: 24),
                const _BudgetSummaryCard(), // Keep existing Flutter functionality
                const SizedBox(height: 24),
                const _CategoryBreakdownCard(),
              ],
            ),
          ),
        ),
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18, color: Colors.blueGrey.shade700), // Calendar icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Report Period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _FilterBar
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
                    DropdownMenuItem(
                        value: ReportDateRangeType.selectedMonthYear,
                        child: Text('Select Month/Year')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Report Period',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (rangeType == ReportDateRangeType.selectedMonthYear) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: ref.watch(selectedMonthProvider),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        ref.read(selectedMonthProvider.notifier).state =
                            newValue;
                        ref.read(reportDateRangeTypeProvider.notifier).state =
                            ReportDateRangeType.selectedMonthYear;
                      }
                    },
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(AppFormatters.getMonthName(month)),
                      );
                    }),
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: ref.watch(selectedYearProvider),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        ref.read(selectedYearProvider.notifier).state =
                            newValue;
                        ref.read(reportDateRangeTypeProvider.notifier).state =
                            ReportDateRangeType.selectedMonthYear;
                      }
                    },
                    items: List.generate(5, (index) {
                      // Show current year and 4 previous years
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 18, color: Colors.blueGrey.shade700), // Wallet icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Income vs Expense',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ), // Closing parenthesis for the Row widget
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _IncomeVsExpenseCard
          breakdownAsync.when(
            data: (data) {
              final totalExpenses = data.needs + data.wants;
              final netFlow = data.income + data.investments - totalExpenses;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                      context,
                      'Total Income',
                      AppFormatters.formatCurrency(data.income, currency),
                      Colors.blue),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      context,
                      'Total Expenses (Needs + Wants)',
                      AppFormatters.formatCurrency(totalExpenses, currency),
                      Colors.red),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      context,
                      'Total Savings (Investments)',
                      AppFormatters.formatCurrency(data.investments, currency),
                      Colors.green),
                  const Divider(height: 24),
                  Text('Net Cash Flow',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatCurrency(netFlow, currency),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  decoration: TextDecoration.none),
              overflow: TextOverflow.ellipsis),
        ),
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.bar_chart,
                  size: 18, color: Colors.blueGrey.shade700), // BarChart3 icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Asset Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _AssetsSummaryCard
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
    );
  }
}

/// Card for Expense Category Breakdown donut chart.
class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.pie_chart,
                  size: 18, color: Colors.blueGrey.shade700), // PieChart icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Expense Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _CategoryBreakdownCard
          const SizedBox(height: 16),
          const CategoryPieChartWidget(),
        ],
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.repeat,
                  size: 18, color: Colors.blueGrey.shade700), // Repeat icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Recurring Costs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _RecurringCostsCard
          subsAsync.when(
            data: (subs) {
              if (subs.isEmpty) return const Text('No subscriptions added.');
              final total =
                  subs.fold<double>(0, (prev, sub) => prev + sub.amount);
              return Column(
                children: [
                  ...subs.map((sub) => ListTile(
                        title: Text(sub.name),
                        trailing: Text(
                            AppFormatters.formatCurrency(sub.amount, currency)),
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.attach_money,
                  size: 18,
                  color: Colors.blueGrey.shade700), // Custom icon for budget
              const SizedBox(width: 8), // gap-2
              Text(
                'Budget Performance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _BudgetSummaryCard
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
    );
  }
}

/// Card for displaying a detailed list of transactions.
class _TransactionListCard extends ConsumerWidget {
  const _TransactionListCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final incomesAsync = ref.watch(filteredIncomeProvider);
    final currency = ref.watch(currencyProvider);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(backgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: lightShadow,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0), // p-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equivalent to h3 className="font-bold mb-3 flex items-center gap-2 text-slate-800"
          Row(
            children: [
              Icon(Icons.list,
                  size: 18, color: Colors.blueGrey.shade700), // List icon
              const SizedBox(width: 8), // gap-2
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3 (approx)

          // Original content of _TransactionListCard
          expensesAsync.when(
            data: (expenses) {
              return incomesAsync.when(
                data: (incomes) {
                  final allTransactions = <dynamic>[...expenses, ...incomes];
                  allTransactions.sort((a, b) => b.date.compareTo(a.date));

                  if (allTransactions.isEmpty) {
                    return const SizedBox(
                        height: 100,
                        child: Center(
                            child: Text('No transactions in this period.')));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = allTransactions[index];
                      if (transaction is Expense) {
                        return ExpenseListItem(
                          expense: transaction,
                          currency: currency,
                        );
                      } else if (transaction is Income) {
                        return IncomeCard(income: transaction);
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading incomes: $e'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error loading expenses: $e'),
          ),
        ],
      ),
    );
  }
}
