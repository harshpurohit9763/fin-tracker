// TODO Implement this library.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui'; // For gradients/glass
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/controllers/report_provider.dart';
import 'package:personal_finance/helper/report_exporter.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart'; // Import isAmoledProvider
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/subscription_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:personal_finance/helper/report_repo.dart';
import '../models/expense_model.dart';

// --- Global Helper for Date Picker ---
Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
  final initialRange = ref.read(currentDateRangeProvider);
  final picked = await showDateRangePicker(
    context: context,
    initialDateRange: initialRange,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Colors.white,
            onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    ref.read(customDateRangeProvider.notifier).state = picked;
    ref.read(reportDateRangeTypeProvider.notifier).state =
        ReportDateRangeType.custom;
  }
}

// --- NEW: Top-level helper for monthly chart titles ---
SideTitles _getMonthlyChartBottomTitles(List<CashFlowData> flowData) {
  return SideTitles(
    showTitles: true,
    reservedSize: 30,
    interval: 1,
    getTitlesWidget: (value, meta) {
      final index = value.toInt();
      if (index >= 0 && index < flowData.length) {
        final data = flowData[index];
        final monthName = AppFormatters.getMonthName(data.month);
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 8.0,
          child: Text(monthName.substring(0, 3),
              style: TextStyle(fontSize: 10.sp)),
        );
      }
      return const Text('');
    },
  );
}

class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAmoled = ref.watch(isAmoledProvider);
    final isDark = theme.brightness ==
        Brightness.dark; // Still needed for other dark mode checks
    // Use pitch black if AMOLED is enabled, otherwise use default dark/light background
    final bgColor = isAmoled
        ? Colors.black
        : (isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE));
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern App Bar ---
          SliverAppBar(
            backgroundColor: bgColor,
            expandedHeight: 80.0,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.white10 : Colors.white,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18.sp, color: theme.iconTheme.color),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            centerTitle: true,
            title: Text(
              'Advanced Reports',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20.sp,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: IconButton(
                    icon: Icon(Icons.download_rounded,
                        size: 20.sp, color: theme.colorScheme.primary),
                    tooltip: 'Export Report',
                    onPressed: () => _handleExport(context, ref),
                  ),
                ),
              ),
            ],
          ),

          // --- Report Content ---
          SliverPadding(
            padding: EdgeInsets.all(20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                const _FilterBar(),
                SizedBox(height: 24.h),
                const _CashFlowCard(),
                SizedBox(height: 24.h),
                const _BudgetSummaryCard(),
                SizedBox(height: 24.h),
                const _CategoryBreakdownCard(),
                SizedBox(height: 24.h),
                const _DailySpendingBarChartCard(), // Replaced scatter plot
                SizedBox(height: 24.h),
                const _AssetsSummaryCard(),
                SizedBox(height: 24.h),
                const _RecurringCostsCard(),
                SizedBox(height: 24.h),
                const _GroupedTransactionListCard(),
                SizedBox(height: 40.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16.w),
            Text('Generating PDF...', style: TextStyle(fontSize: 14.sp)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Data gathering (Preserved logic)
    final dateRange = ref.read(currentDateRangeProvider);
    final currency = ref.read(currencyProvider);
    final expenses = await ref.read(allExpensesForReportProvider.future);
    final incomes = await ref.read(allIncomesForReportProvider.future);
    final spendingBreakdown = await ref.read(spendingBreakdownProvider.future);
    final assets = ref.read(assetListProvider).value ?? [];
    final subscriptions = ref.read(subscriptionListProvider).value ?? [];
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
  }
}

// --- Shared: Modern Card Container ---
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon,
                    size: 18.sp, color: iconColor ?? theme.colorScheme.primary),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }
}

// --- Filter Bar (Control Panel Style) ---
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeType = ref.watch(reportDateRangeTypeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [const Color(0xFFF0F4FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Settings',
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor)),
          SizedBox(height: 12.h),
          _buildDropdown(
            context,
            value: rangeType,
            items: [
              _buildItem(ReportDateRangeType.thisMonth, 'This Month'),
              _buildItem(ReportDateRangeType.last7Days, 'Last 7 Days'),
              _buildItem(ReportDateRangeType.last30Days, 'Last 30 Days'),
              _buildItem(ReportDateRangeType.custom, 'Custom Range...'),
              _buildItem(
                  ReportDateRangeType.selectedMonthYear, 'Select Month/Year'),
            ],
            onChanged: (newValue) {
              if (newValue == ReportDateRangeType.custom) {
                _selectCustomDateRange(context, ref);
              } else {
                ref.read(reportDateRangeTypeProvider.notifier).state =
                    newValue!;
              }
            },
          ),
          if (rangeType == ReportDateRangeType.selectedMonthYear) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    context,
                    value: ref.watch(selectedMonthProvider),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(AppFormatters.getMonthName(month)),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedMonthProvider.notifier).state = val;
                        ref.read(reportDateRangeTypeProvider.notifier).state =
                            ReportDateRangeType.selectedMonthYear;
                      }
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildDropdown<int>(
                    context,
                    value: ref.watch(selectedYearProvider),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                          value: year, child: Text(year.toString()));
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedYearProvider.notifier).state = val;
                        ref.read(reportDateRangeTypeProvider.notifier).state =
                            ReportDateRangeType.selectedMonthYear;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  DropdownMenuItem<ReportDateRangeType> _buildItem(
      ReportDateRangeType value, String text) {
    return DropdownMenuItem(value: value, child: Text(text));
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: theme.primaryColor),
          items: items,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        ),
      ),
    );
  }
}

// --- NEW: Provider for Daily Spending Chart ---
final dailySpendingProvider =
    FutureProvider.autoDispose<Map<DateTime, double>>((ref) {
  final dateRange = ref.watch(currentDateRangeProvider);
  return ref
      .watch(reportRepositoryProvider)
      .getDailySpending(dateRange.start, dateRange.end);
});

// --- Provider for Chart Data ---
final monthlyCashFlowProvider =
    FutureProvider.autoDispose<List<CashFlowData>>((ref) {
  final dateRange = ref.watch(currentDateRangeProvider);
  return ref
      .watch(reportRepositoryProvider)
      .getMonthlyCashFlow(dateRange.start, dateRange.end);
});

// --- Charts: Income vs Expense (Gradient Area Chart) ---
class _CashFlowCard extends ConsumerWidget {
  const _CashFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(monthlyCashFlowProvider);

    return _ReportCard(
      title: 'Income vs Expense',
      icon: Icons.stacked_line_chart_rounded,
      iconColor: Colors.blueAccent,
      child: cashFlowAsync.when(
        data: (flowData) {
          if (flowData.isEmpty) {
            return _buildEmptyState(context, 'No data for period.');
          }

          List<FlSpot> incomeSpots = [];
          List<FlSpot> expenseSpots = [];
          double maxY = 0;

          for (int i = 0; i < flowData.length; i++) {
            final item = flowData[i];
            final double x = i.toDouble();
            final double income = item.income;
            final double expense = item.expenses;

            incomeSpots.add(FlSpot(x, income));
            expenseSpots.add(FlSpot(x, expense));

            if (income > maxY) maxY = income;
            if (expense > maxY) maxY = expense;
          }

          return Column(
            children: [
              SizedBox(
                height: 200.h,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context).dividerColor.withOpacity(0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: _getMonthlyChartBottomTitles(flowData)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _buildLine(incomeSpots, Colors.greenAccent.shade700),
                      _buildLine(expenseSpots, Colors.redAccent.shade400),
                    ],
                    minY: 0,
                    maxY: maxY * 1.2,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend(Colors.greenAccent.shade700, 'Income'),
                  SizedBox(width: 16.w),
                  _buildLegend(Colors.redAccent.shade400, 'Expense'),
                ],
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.4,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(text, style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }
}

// --- Charts: Expense Breakdown (Styled Radar) ---
class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesForReportProvider);
    final theme = Theme.of(context);

    return _ReportCard(
      title: 'Category Breakdown',
      icon: Icons.radar_rounded,
      iconColor: Colors.purpleAccent,
      child: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty)
            return _buildEmptyState(context, 'No expenses.');

          final categoryTotals = <String, double>{};
          for (var expense in expenses) {
            categoryTotals.update(
                expense.category, (value) => value + expense.amount,
                ifAbsent: () => expense.amount);
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topCategories = sortedCategories.take(5).toList();

          // RadarChart requires at least 3 entries to render.
          if (topCategories.length < 3) {
            return _buildEmptyState(
                context, 'Need at least 3 categories for chart.');
          }

          return SizedBox(
            height: 250.h,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: topCategories
                        .map((e) => RadarEntry(value: e.value))
                        .toList(),
                    borderColor: theme.colorScheme.primary,
                    fillColor: theme.colorScheme.primary.withOpacity(0.2),
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(color: Colors.transparent),
                tickCount: 3,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 0),
                gridBorderData: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1), width: 1),
                titlePositionPercentageOffset: 0.1,
                getTitle: (index, angle) {
                  // shorten label if needed
                  String label = topCategories[index].key;
                  if (label.length > 8) label = '${label.substring(0, 7)}...';

                  return RadarChartTitle(
                      text: label, angle: angle, positionPercentageOffset: 0.1);
                },
                titleTextStyle:
                    TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }
}

// --- List Card: Assets ---
class _AssetsSummaryCard extends ConsumerWidget {
  const _AssetsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final currency = ref.watch(currencyProvider);

    return _ReportCard(
      title: 'Net Worth Assets',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Colors.teal,
      child: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty)
            return _buildEmptyState(context, 'No assets found.');
          final total = assets.fold<double>(0, (p, c) => p + c.value);

          return Column(
            children: [
              ...assets.map((asset) => _buildListItem(context,
                  title: asset.name,
                  amount: asset.value,
                  currency: currency,
                  icon: Icons.circle,
                  iconColor: Colors.teal.withOpacity(0.7))),
              Divider(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Value',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  Text(AppFormatters.formatCurrency(total, currency),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: Colors.teal)),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }
}

// --- List Card: Recurring Costs ---
class _RecurringCostsCard extends ConsumerWidget {
  const _RecurringCostsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionListProvider);
    final currency = ref.watch(currencyProvider);

    return _ReportCard(
      title: 'Recurring Commitments',
      icon: Icons.sync_rounded,
      iconColor: Colors.orangeAccent,
      child: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty)
            return _buildEmptyState(context, 'No subscriptions.');
          final total = subs.fold<double>(0, (p, c) => p + c.amount);

          return Column(
            children: [
              ...subs.map((sub) => _buildListItem(context,
                  title: sub.name,
                  amount: sub.amount,
                  currency: currency,
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.orangeAccent)),
              Divider(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Monthly',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  Text(AppFormatters.formatCurrency(total, currency),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: Colors.orange)),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }
}

// --- Chart: Budget Performance (Donut) ---
class _BudgetSummaryCard extends ConsumerWidget {
  const _BudgetSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallBudgetAsync = ref.watch(overallBudgetProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return _ReportCard(
      title: 'Budget Health',
      icon: Icons.health_and_safety_rounded,
      iconColor: Colors.redAccent,
      child: overallBudgetAsync.when(
        data: (data) {
          final spent = data['spent']!;
          final total = data['total']!;
          if (total == 0) return _buildEmptyState(context, 'No budget set.');

          final remaining = total - spent;
          final isOver = spent > total;

          return Row(
            children: [
              SizedBox(
                height: 100.h,
                width: 100.w,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: spent,
                        color: isOver ? Colors.red : theme.colorScheme.primary,
                        radius: 12.r,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: remaining > 0 ? remaining : 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        radius: 12.r,
                        showTitle: false,
                      ),
                    ],
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 35.r,
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent',
                        style:
                            TextStyle(color: theme.hintColor, fontSize: 12.sp)),
                    Text(AppFormatters.formatCurrency(spent, currency),
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    LinearProgressIndicator(
                      value: (spent / total).clamp(0.0, 1.0),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: isOver ? Colors.red : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Target: ${AppFormatters.formatCurrency(total, currency)}',
                      style: TextStyle(fontSize: 10.sp, color: theme.hintColor),
                    ),
                  ],
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }
}

// --- Chart: Daily Spending Bar Chart (Replaces Scatter Plot) ---
class _DailySpendingBarChartCard extends ConsumerWidget {
  const _DailySpendingBarChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySpendingAsync = ref.watch(dailySpendingProvider);
    final dateRange = ref.watch(currentDateRangeProvider);
    final theme = Theme.of(context);

    return _ReportCard(
      title: 'Daily Spending Pattern',
      icon: Icons.bar_chart_rounded,
      iconColor: Colors.indigoAccent,
      child: dailySpendingAsync.when(
        data: (dailyTotals) {
          if (dailyTotals.isEmpty) {
            return _buildEmptyState(
                context, 'No spending data for this period.');
          }

          final barGroups = <BarChartGroupData>[];
          double maxY = 0;
          final daysInRange = dateRange.end.difference(dateRange.start).inDays;

          for (int i = 0; i <= daysInRange; i++) {
            final currentDate = dateRange.start.add(Duration(days: i));
            final mapKey =
                DateTime(currentDate.year, currentDate.month, currentDate.day);
            final dailyTotal = dailyTotals[mapKey] ?? 0.0;
            if (dailyTotal > maxY) maxY = dailyTotal;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailyTotal,
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    width: 6,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: _getBarChartTitles(context, dateRange),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final currency = ref.read(currencyProvider);
                      return BarTooltipItem(
                        AppFormatters.formatCurrency(rod.toY, currency),
                        TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  FlTitlesData _getBarChartTitles(
      BuildContext context, DateTimeRange dateRange) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final daysInRange =
                dateRange.end.difference(dateRange.start).inDays;
            final index = value.toInt();

            // Smartly show labels to avoid clutter
            if (daysInRange <= 14) {
              final date = dateRange.start.add(Duration(days: index));
              if (date.day % 2 != 0) {
                return Text('${date.day}', style: TextStyle(fontSize: 10.sp));
              }
            } else if (index == 0 ||
                index == daysInRange ||
                index == daysInRange ~/ 2) {
              final date = dateRange.start.add(Duration(days: index));
              return Text('${date.day}/${date.month}',
                  style: TextStyle(fontSize: 10.sp));
            }
            return const Text('');
          },
        ),
      ),
    );
  }
}

// --- Grouped Transactions (Accordion Style) ---
class _GroupedTransactionListCard extends ConsumerStatefulWidget {
  const _GroupedTransactionListCard();

  @override
  ConsumerState<_GroupedTransactionListCard> createState() =>
      __GroupedTransactionListCardState();
}

class __GroupedTransactionListCardState
    extends ConsumerState<_GroupedTransactionListCard> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final incomesAsync = ref.watch(filteredIncomeProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _ReportCard(
      title: 'Detailed Transactions',
      icon: Icons.receipt_long_rounded,
      iconColor: Colors.grey,
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, color: theme.hintColor),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ),
          SizedBox(height: 16.h),

          expensesAsync.when(
            data: (expenses) {
              return incomesAsync.when(
                data: (incomes) {
                  final query = _searchQuery.toLowerCase();

                  // Filter
                  final filteredExpenses = expenses
                      .where((tx) =>
                          (tx.description?.toLowerCase().contains(query) ??
                              false) ||
                          tx.category.toLowerCase().contains(query))
                      .toList();

                  final filteredIncomes = incomes
                      .where((tx) =>
                          tx.description.toLowerCase().contains(query) ||
                          tx.source.toLowerCase().contains(query))
                      .toList();

                  final allFiltered = [...filteredExpenses, ...filteredIncomes];

                  if (allFiltered.isEmpty)
                    return _buildEmptyState(context, 'No transactions found.');

                  // Group
                  final grouped = <String, List<dynamic>>{};
                  final groupTotals = <String, double>{};

                  for (final tx in allFiltered) {
                    String groupKey;
                    double amount;
                    if (tx is Expense) {
                      groupKey = tx.category;
                      amount = -tx.amount;
                    } else {
                      groupKey = (tx as Income).source;
                      amount = tx.amount;
                    }
                    grouped.putIfAbsent(groupKey, () => []).add(tx);
                    groupTotals.update(groupKey, (v) => v + amount,
                        ifAbsent: () => amount);
                  }

                  // Sort
                  final sortedKeys = groupTotals.keys.toList()
                    ..sort((a, b) =>
                        groupTotals[b]!.abs().compareTo(groupTotals[a]!.abs()));

                  return Column(
                    children: sortedKeys.map((key) {
                      final total = groupTotals[key]!;
                      final items = grouped[key]!;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: theme.dividerColor.withOpacity(0.3)),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(key,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp)),
                            trailing: Text(
                              AppFormatters.formatCurrency(total, currency),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: total >= 0 ? Colors.green : Colors.red,
                                  fontSize: 14.sp),
                            ),
                            childrenPadding: EdgeInsets.only(bottom: 12.h),
                            children: items.map((tx) {
                              if (tx is Expense) {
                                return ExpenseListItem(
                                    expense: tx, currency: currency);
                              } else {
                                return IncomeCard(income: tx as Income);
                              }
                            }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
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

// --- Common UI Helpers ---

Widget _buildEmptyState(BuildContext context, String message) {
  return SizedBox(
    height: 100.h,
    child: Center(
      child: Text(message,
          style: TextStyle(color: Theme.of(context).disabledColor)),
    ),
  );
}

Widget _buildListItem(
  BuildContext context, {
  required String title,
  required double amount,
  required String currency,
  required IconData icon,
  required Color iconColor,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Row(
      children: [
        Icon(icon, size: 12.sp, color: iconColor),
        SizedBox(width: 8.w),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14.sp))),
        Text(
          AppFormatters.formatCurrency(amount, currency),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
