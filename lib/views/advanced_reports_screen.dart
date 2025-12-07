import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/controllers/report_provider.dart';
import 'package:personal_finance/helper/report_exporter.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/subscription_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:personal_finance/helper/report_repo.dart';
import '../models/expense_model.dart';

/// Helper function to show the date range picker and update providers.
/// This is moved to the top level to avoid code duplication.
Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
  final initialRange = ref.read(currentDateRangeProvider);
  final picked = await showDateRangePicker(
    context: context,
    initialDateRange: initialRange,
    firstDate: DateTime(2000),
    lastDate: DateTime.now()
        .add(const Duration(days: 365 * 5)), // Allow selecting future dates
  );

  if (picked != null) {
    ref.read(customDateRangeProvider.notifier).state = picked;
    ref.read(reportDateRangeTypeProvider.notifier).state =
        ReportDateRangeType.custom;
  }
}

/// Main screen for displaying advanced, filterable reports.
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Advanced Reports', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true, // Center the title for better aesthetics
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Report',
            onPressed: () async {
              // Show a loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Generating report...',
                        style: TextStyle(fontSize: 14.sp))),
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
                // cashFlowData: cashFlowData,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: const [
          _FilterBar(),
          _CashFlowCard(),
          _BudgetSummaryCard(),
          _CategoryBreakdownCard(),
          _ExpenseScatterPlotCard(),
          _AssetsSummaryCard(),
          _RecurringCostsCard(),
          _GroupedTransactionListCard(),
        ],
      ),
    );
  }
}

/// A reusable card widget for report sections to maintain a consistent UI.
class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lightShadow = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Color.lerp(backgroundColor, Colors.white, 0.7)!;
    final darkShadow = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: const Offset(4, 4),
            blurRadius: 15,
          ),
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-4, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18.sp,
                  color: iconColor ??
                      Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

/// A bar with dropdowns to filter all reports on the screen.
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeType = ref.watch(reportDateRangeTypeProvider);

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lightShadow = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Color.lerp(backgroundColor, Colors.white, 0.7)!;
    final darkShadow = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: const Offset(4, 4),
            blurRadius: 15,
          ),
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-4, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18.sp,
                  color: Colors.blueGrey.shade700), // Calendar icon
              SizedBox(width: 8.w), // gap-2
              Text(
                'Report Period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, // font-bold
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.sp,
                    ),
              ),
            ],
          ),

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
                  items: [
                    DropdownMenuItem(
                        value: ReportDateRangeType.thisMonth,
                        child: Text('This Month',
                            style: TextStyle(fontSize: 14.sp))),
                    DropdownMenuItem(
                        value: ReportDateRangeType.last7Days,
                        child: Text('Last 7 Days',
                            style: TextStyle(fontSize: 14.sp))),
                    DropdownMenuItem(
                        value: ReportDateRangeType.last30Days,
                        child: Text('Last 30 Days',
                            style: TextStyle(fontSize: 14.sp))),
                    DropdownMenuItem(
                        value: ReportDateRangeType.custom,
                        child: Text('Custom Range...',
                            style: TextStyle(fontSize: 14.sp))),
                    DropdownMenuItem(
                        value: ReportDateRangeType.selectedMonthYear,
                        child: Text('Select Month/Year',
                            style: TextStyle(fontSize: 14.sp))),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Report Period',
                    labelStyle: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
            ],
          ),
          if (rangeType == ReportDateRangeType.selectedMonthYear) ...[
            SizedBox(height: 12.h),
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
                        child: Text(AppFormatters.getMonthName(month),
                            style: TextStyle(fontSize: 14.sp)),
                      );
                    }),
                    decoration: InputDecoration(
                      labelText: 'Month',
                      labelStyle: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
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
                        child: Text(year.toString(),
                            style: TextStyle(fontSize: 14.sp)),
                      );
                    }),
                    decoration: InputDecoration(
                      labelText: 'Year',
                      labelStyle: TextStyle(fontSize: 14.sp),
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

/// A provider to fetch monthly cash flow data.
/// This makes the data available to the chart widget reactively.
final monthlyCashFlowProvider =
    FutureProvider.autoDispose<List<CashFlowData>>((ref) {
  final dateRange = ref.watch(currentDateRangeProvider);
  return ref
      .watch(reportRepositoryProvider)
      .getMonthlyCashFlow(dateRange.start, dateRange.end);
});

/// Card for Income vs. Expense trend chart, now using an Area Chart.
class _CashFlowCard extends ConsumerWidget {
  const _CashFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(monthlyCashFlowProvider);
    final currency = ref.watch(currencyProvider);

    return _ReportCard(
      title: 'Income vs Expense',
      icon: Icons.show_chart,
      child: cashFlowAsync.when(
        data: (flowData) {
          if (flowData.isEmpty) {
            return SizedBox(
                height: 150.h,
                child: Center(
                    child: Text('No cash flow data for this period.',
                        style: TextStyle(fontSize: 14.sp))));
          }

          List<FlSpot> incomeSpots = [];
          List<FlSpot> expenseSpots = [];
          double maxX = 0;
          double maxY = 0;

          for (int i = 0; i < flowData.length; i++) {
            final item = flowData[i];
            final double x = i.toDouble();
            final double income = item.income;
            final double expense = item.expenses;

            incomeSpots.add(FlSpot(x, income));
            expenseSpots.add(FlSpot(x, expense));

            if (x > maxX) maxX = x;
            if (income > maxY) maxY = income;
            if (expense > maxY) maxY = expense;
          }

          return SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLineChartBarData(incomeSpots, Colors.green),
                  _buildLineChartBarData(expenseSpots, Colors.red),
                ],
                minY: 0,
                maxY: maxY * 1.2, // Add some padding to the top
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading cash flow: $e',
            style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3.w,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.2),
      ),
    );
  }
}

/// Card for Expense Category Breakdown using a Radar Chart.
class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesForReportProvider);

    return _ReportCard(
      title: 'Expense Breakdown',
      icon: Icons.radar,
      child: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return SizedBox(
                height: 150.h,
                child: Center(
                    child: Text('No expense data for this period.',
                        style: TextStyle(fontSize: 14.sp))));
          }

          final categoryTotals = <String, double>{};
          for (var expense in expenses) {
            categoryTotals.update(
                expense.category, (value) => value + expense.amount,
                ifAbsent: () => expense.amount);
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topCategories = sortedCategories.take(6).toList();

          // Radar chart requires at least 3 data points to render.
          if (topCategories.length < 3) {
            return SizedBox(
                height: 150.h,
                child: Center(
                    child: Text(
                        'Not enough data for Radar Chart (requires at least 3 categories).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp))));
          }

          final maxValue = topCategories.map((e) => e.value).reduce(max) * 1.2;

          return SizedBox(
            height: 250.h,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: topCategories
                        .map((e) => RadarEntry(value: e.value))
                        .toList(),
                    borderColor: Theme.of(context).colorScheme.primary,
                    fillColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                ],
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 0),
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: topCategories[index].key,
                    angle: angle,
                  );
                },
                titlePositionPercentageOffset: 0.2,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error loading expenses: $e',
            style: TextStyle(fontSize: 14.sp)),
      ),
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

    return _ReportCard(
      title: 'Asset Summary',
      icon: Icons.bar_chart,
      child: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return Text('No assets added.', style: TextStyle(fontSize: 14.sp));
          }
          final total =
              assets.fold<double>(0, (prev, asset) => prev + asset.value);
          return Column(
            children: [
              ...assets.map((asset) => ListTile(
                    title: Text(asset.name, style: TextStyle(fontSize: 16.sp)),
                    trailing: Text(
                        AppFormatters.formatCurrency(asset.value, currency),
                        style: TextStyle(fontSize: 16.sp)),
                  )),
              const Divider(),
              ListTile(
                title: Text('Total Assets',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
                trailing: Text(AppFormatters.formatCurrency(total, currency),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e', style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }
}

/// Card for showing daily spending patterns using a Scatter Plot.
class _ExpenseScatterPlotCard extends ConsumerWidget {
  const _ExpenseScatterPlotCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesForReportProvider);
    final dateRange = ref.watch(currentDateRangeProvider);

    return _ReportCard(
      title: 'Daily Spending Pattern',
      icon: Icons.scatter_plot,
      child: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return SizedBox(
                height: 150.h,
                child: Center(
                    child: Text('No spending data for this period.',
                        style: TextStyle(fontSize: 14.sp))));
          }

          final spots = expenses.map((e) {
            return ScatterSpot(
              e.date.day.toDouble(),
              e.amount,
              dotPainter: FlDotCirclePainter(
                radius: (e.amount / 100).clamp(2, 10).toDouble(),
                color: Theme.of(context).colorScheme.error.withOpacity(0.7),
              ),
            );
          }).toList();

          return SizedBox(
            height: 200.h,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots,
                minX: 1,
                maxX: dateRange.end.day.toDouble(),
                minY: 0,
                gridData: const FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e', style: TextStyle(fontSize: 14.sp)),
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

    return _ReportCard(
      title: 'Recurring Costs',
      icon: Icons.repeat,
      child: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return Text('No subscriptions added.',
                style: TextStyle(fontSize: 14.sp));
          }
          final total = subs.fold<double>(0, (prev, sub) => prev + sub.amount);
          return Column(
            children: [
              ...subs.map((sub) => ListTile(
                    title: Text(sub.name, style: TextStyle(fontSize: 16.sp)),
                    trailing: Text(
                        AppFormatters.formatCurrency(sub.amount, currency),
                        style: TextStyle(fontSize: 16.sp)),
                  )),
              const Divider(),
              ListTile(
                title: Text('Total Monthly Cost',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
                trailing: Text(AppFormatters.formatCurrency(total, currency),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e', style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }
}

/// Card for Budget Summary, now with a Donut/Gauge-style chart.
class _BudgetSummaryCard extends ConsumerWidget {
  const _BudgetSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallBudgetAsync = ref.watch(overallBudgetProvider);
    final currency = ref.watch(currencyProvider);

    return _ReportCard(
      title: 'Budget Performance',
      icon: Icons.attach_money,
      child: overallBudgetAsync.when(
        data: (data) {
          final spent = data['spent']!;
          final total = data['total']!;
          if (total == 0) {
            return SizedBox(
                height: 100.h,
                child: Center(
                    child: Text('No budgets set for this period.',
                        style: TextStyle(fontSize: 14.sp))));
          }
          final percentage = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
          final remaining = total - spent;

          return Column(
            children: [
              SizedBox(
                height: 120.h,
                width: 120.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: spent,
                            color: Theme.of(context).colorScheme.primary,
                            radius: 15.r,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: remaining > 0 ? remaining : 0,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            radius: 15.r,
                            showTitle: false,
                          ),
                        ],
                        startDegreeOffset: -90,
                        sectionsSpace: 0,
                        centerSpaceRadius: 40.r,
                      ),
                    ),
                    Text('${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 22.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                  '${AppFormatters.formatCurrency(spent, currency)} of ${AppFormatters.formatCurrency(total, currency)}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e', style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }
}

/// Card for displaying a detailed list of transactions, now grouped by category/source.
class _GroupedTransactionListCard extends ConsumerStatefulWidget {
  const _GroupedTransactionListCard();

  @override
  ConsumerState<_GroupedTransactionListCard> createState() =>
      __GroupedTransactionListCardState();
}

class __GroupedTransactionListCardState
    extends ConsumerState<_GroupedTransactionListCard> {
  String _searchQuery = '';

  Widget _buildSearchAndFilter() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search transactions by description or category...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final incomesAsync = ref.watch(filteredIncomeProvider);
    final currency = ref.watch(currencyProvider);

    return _ReportCard(
      title: 'Transactions',
      icon: Icons.list,
      child: Column(
        children: [
          _buildSearchAndFilter(),
          SizedBox(height: 16.h),
          expensesAsync.when(
            data: (expenses) {
              return incomesAsync.when(
                data: (incomes) {
                  // 1. Filter transactions based on search query
                  final query = _searchQuery.toLowerCase();
                  final filteredExpenses = expenses.where((tx) {
                    if (_searchQuery.isEmpty) return true;
                    return (tx.description?.toLowerCase().contains(query) ??
                            false) ||
                        tx.category.toLowerCase().contains(query);
                  }).toList();

                  final filteredIncomes = incomes.where((tx) {
                    if (_searchQuery.isEmpty) return true;
                    return tx.description.toLowerCase().contains(query) ||
                        tx.source.toLowerCase().contains(query);
                  }).toList();

                  final allFiltered = <dynamic>[
                    ...filteredExpenses,
                    ...filteredIncomes
                  ];

                  if (allFiltered.isEmpty) {
                    return SizedBox(
                        height: 100.h,
                        child: Center(
                            child: Text('No matching transactions found.',
                                style: TextStyle(fontSize: 14.sp))));
                  }

                  // 2. Group the filtered transactions
                  final grouped = <String, List<dynamic>>{};
                  final groupTotals = <String, double>{};

                  for (final tx in allFiltered) {
                    String groupKey;
                    double amount;
                    if (tx is Expense) {
                      groupKey = tx.category;
                      amount = -tx.amount;
                    } else if (tx is Income) {
                      groupKey = tx.source;
                      amount = tx.amount;
                    } else {
                      continue;
                    }

                    grouped.putIfAbsent(groupKey, () => []).add(tx);
                    groupTotals.update(groupKey, (value) => value + amount,
                        ifAbsent: () => amount);
                  }

                  // 3. Sort groups by total amount (descending absolute value)
                  final sortedGroupKeys = groupTotals.keys.toList()
                    ..sort((a, b) =>
                        groupTotals[b]!.abs().compareTo(groupTotals[a]!.abs()));

                  // 4. Build expandable list
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final groupKey = sortedGroupKeys[index];
                      final transactionsInGroup = grouped[groupKey]!;
                      final total = groupTotals[groupKey]!;

                      return ExpansionTile(
                        title: Text(groupKey,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.sp)),
                        trailing: Text(
                          AppFormatters.formatCurrency(total, currency),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: total >= 0 ? Colors.green : null),
                        ),
                        children: transactionsInGroup.map((tx) {
                          if (tx is Expense) {
                            return ExpenseListItem(
                                expense: tx, currency: currency);
                          } else if (tx is Income) {
                            return IncomeCard(income: tx);
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading incomes: $e',
                    style: TextStyle(fontSize: 14.sp)),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error loading expenses: $e',
                style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}
