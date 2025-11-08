import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/dashboard_provider.dart';

class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(last6MonthsSpendingProvider);

    return spendingAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Not enough data to show trend.'));
        }

        final List<BarChartGroupData> barGroups = [];
        int i = 0;
        double maxY = 0;

        for (var entry in data.entries) {
          final barData = BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).colorScheme.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
          barGroups.add(barData);
          if (entry.value > maxY) maxY = entry.value;
          i++;
        }

        return BarChart(
          BarChartData(
            maxY: maxY * 1.2, // Add 20% padding to top
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final month = data.keys.elementAt(group.x);
                  return BarTooltipItem(
                    '$month\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: NumberFormat.simpleCurrency(
                          decimalDigits: 0,
                        ).format(rod.toY),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.keys.length)
                      return Container();
                    // Format '2025-11' to 'Nov'
                    final monthYear = data.keys.elementAt(index);
                    final date = DateTime.parse('${monthYear}-01');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat.MMM().format(date)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: barGroups,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
