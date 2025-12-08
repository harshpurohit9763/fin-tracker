import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/controllers/expense_provider.dart'; // Import for daily data
import 'package:personal_finance/helper/app_formater.dart';

// Enum for the view mode
enum TrendViewMode { yearly, monthly }

// Provider to manage the selected view mode
final trendViewModeProvider =
    StateProvider<TrendViewMode>((ref) => TrendViewMode.yearly);

// Provider to manage the selected month for "Monthly" view (default to current month)
final trendSelectedMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providers
    final viewMode = ref.watch(trendViewModeProvider);
    final selectedMonthDate = ref.watch(trendSelectedMonthProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- DATA LOGIC ---
    // 1. Yearly Data (Last 6-12 months)
    final yearlyAsync = ref.watch(last6MonthsSpendingProvider);

    // 2. Monthly Data (Daily spending for selected month)
    // You might need to create a specific provider for this if 'filteredExpenseListProvider' isn't suitable.
    // For now, I'm assuming we filter 'allExpensesProvider' or similar.
    final allExpensesAsync = ref.watch(expenseListProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Title + Toggle ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor,
                ),
              ),
              // Segmented Control
              Container(
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(
                        context, ref, TrendViewMode.yearly, 'Yearly'),
                    _buildToggleBtn(
                        context, ref, TrendViewMode.monthly, 'Monthly'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- SUB-HEADER: Amount + Dropdown (if Monthly) ---
          if (viewMode == TrendViewMode.monthly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dropdown to pick specific month
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedMonthDate.month,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      isDense: true,
                      items: List.generate(12, (index) {
                        // Generate last 12 months options relative to now, or just Jan-Dec of current year
                        final date = DateTime(DateTime.now().year, index + 1);
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            DateFormat.MMMM().format(date),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          // Update selected month (keep current year)
                          final newDate = DateTime(DateTime.now().year, val);
                          ref.read(trendSelectedMonthProvider.notifier).state =
                              newDate;
                        }
                      },
                    ),
                  ),
                ),
                // We can add month total here later
              ],
            ),

          const SizedBox(height: 24),

          // --- CHART RENDERING ---
          SizedBox(
            height: 200,
            child: viewMode == TrendViewMode.yearly
                ? _buildYearlyChart(yearlyAsync, currency, theme)
                : _buildMonthlyChart(
                    allExpensesAsync, selectedMonthDate, currency, theme),
          ),
        ],
      ),
    );
  }

  // --- Toggle Button Widget ---
  Widget _buildToggleBtn(
      BuildContext context, WidgetRef ref, TrendViewMode mode, String label) {
    final currentMode = ref.watch(trendViewModeProvider);
    final isSelected = currentMode == mode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        ref.read(trendViewModeProvider.notifier).state = mode;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.hintColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- CHART 1: YEARLY (Line Chart) ---
  Widget _buildYearlyChart(AsyncValue<Map<String, double>> dataAsync,
      String currency, ThemeData theme) {
    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) return const Center(child: Text("No data"));

        // Convert Map to Spots
        final spots = List.generate(data.length, (index) {
          return FlSpot(index.toDouble(), data.values.elementAt(index));
        });

        // Find Max Y for scaling
        double maxY = 0;
        for (var val in data.values) if (val > maxY) maxY = val;

        return LineChart(LineChartData(
            maxY: maxY * 1.2,
            minY: 0,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length)
                      return const SizedBox();
                    // Parse "YYYY-MM" to "MMM"
                    final key = data.keys.elementAt(index);
                    final date = DateFormat("yyyy-MM").parse(key);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat.MMM().format(date),
                          style:
                              TextStyle(fontSize: 10, color: theme.hintColor)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.3),
                          theme.colorScheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )))
            ]));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text("Error loading chart")),
    );
  }

  // --- CHART 2: MONTHLY (Daily Breakdown) ---
  Widget _buildMonthlyChart(AsyncValue<List<dynamic>> expensesAsync,
      DateTime selectedMonth, String currency, ThemeData theme) {
    return expensesAsync.when(
      data: (allExpenses) {
        // Filter expenses for the selected month
        final expensesInMonth = allExpenses.where((e) {
          return e.date.year == selectedMonth.year &&
              e.date.month == selectedMonth.month;
        }).toList();

        if (expensesInMonth.isEmpty) {
          return Center(
              child: Text(
                  "No expenses in ${DateFormat.MMMM().format(selectedMonth)}"));
        }

        // Aggregate by Day (1..31)
        // Map<DayInt, TotalAmount>
        final Map<int, double> dailyTotals = {};
        for (var e in expensesInMonth) {
          final day = e.date.day;
          dailyTotals.update(day, (val) => val + e.amount,
              ifAbsent: () => e.amount);
        }

        // Create spots for every day (or just days with data)
        // To make a smooth line, we might want to fill gaps with 0,
        // but for scatter/bar, gaps are fine. Let's use Line for consistency.
        final daysInMonth =
            DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
        List<FlSpot> spots = [];
        double maxY = 0;

        for (int i = 1; i <= daysInMonth; i++) {
          final amount = dailyTotals[i] ?? 0.0;
          if (amount > maxY) maxY = amount;
          spots.add(FlSpot(i.toDouble(), amount));
        }

        return LineChart(LineChartData(
            maxY: maxY * 1.2,
            minY: 0,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 5, // Show label every 5 days
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt();
                    if (day == 0 || day > daysInMonth) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(day.toString(),
                          style:
                              TextStyle(fontSize: 10, color: theme.hintColor)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                  spots: spots,
                  isCurved: true, // Smooth line for daily fluctuations
                  curveSmoothness: 0.2,
                  color: theme
                      .colorScheme.secondary, // Different color for daily view
                  barWidth: 2,
                  dotData: const FlDotData(
                      show: false), // Hide dots for cleaner look on 30 points
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.secondary.withOpacity(0.3),
                          theme.colorScheme.secondary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )))
            ],
            lineTouchData: LineTouchData(touchTooltipData:
                LineTouchTooltipData(getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                    "${DateFormat.MMM().format(selectedMonth)} ${spot.x.toInt()}\n",
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                          text: AppFormatters.formatCurrency(spot.y, currency),
                          style: const TextStyle(fontWeight: FontWeight.normal))
                    ]);
              }).toList();
            }))));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text("Error loading daily data")),
    );
  }
}
