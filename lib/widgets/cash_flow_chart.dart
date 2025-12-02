import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/helper/report_repo.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class CashFlowChart extends ConsumerWidget {
  final List<CashFlowData> cashFlowData;

  const CashFlowChart({super.key, required this.cashFlowData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cashFlowData.isEmpty) {
      return const Center(
        child:
            Text('Not enough data to display cash flow chart (min 2 months).'),
      );
    }

    // Convert cashFlowData to BarChartGroupData
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < cashFlowData.length; i++) {
      final data = cashFlowData[i];
      final incomeBar = BarChartRodData(
        toY: data.income,
        color: Theme.of(context).colorScheme.primary, // Income accent color
        width: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      );
      final expenseBar = BarChartRodData(
        toY: data.expenses,
        color: Theme.of(context).colorScheme.error, // Expense accent color
        width: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      );
      final netFlowBar = BarChartRodData(
        toY: data.netFlow,
        color: Theme.of(context).colorScheme.secondary, // Net flow accent color
        width: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      );

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [incomeBar, expenseBar, netFlowBar],
          barsSpace: 4,
        ),
      );

      // Update maxY
      if (data.income > maxY) maxY = data.income;
      if (data.expenses > maxY) maxY = data.expenses;
      if (data.netFlow > maxY) maxY = data.netFlow;
    }

    return SizedBox(
      height: 150, // Compact height
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2, // Add padding
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false), // Disable touch
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < cashFlowData.length) {
                    final data = cashFlowData[index];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        '${AppFormatters.monthAbbreviations[data.month - 1]}', // Only month abbreviation
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false), // Remove grid lines
          borderData: FlBorderData(show: false), // Remove border
          barGroups: barGroups,
        ),
      ),
    );
  }
}
