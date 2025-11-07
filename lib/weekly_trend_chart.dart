import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/report_provider.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';

class WeeklyTrendChartWidget extends ConsumerWidget {
  const WeeklyTrendChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final weeklyTrendAsync = ref.watch(weeklyTrendProvider);

    return weeklyTrendAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No data for this month.'));
        }

        final spots = data.entries.map((entry) {
          // entry.key is week number (X-axis), entry.value is amount (Y-axis)
          return FlSpot(entry.key.toDouble(), entry.value);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Wk ${value.toInt()}'),
                    );
                  },
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return Container();
                    return Text(
                      AppFormatters.formatCurrency(value, currency)
                          .replaceAll('\$', '')
                          .replaceAll('.00', 'k'), // Simplified
                    );
                  },
                  reservedSize: 60,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: data.keys.first.toDouble(),
            maxX: data.keys.last.toDouble(),
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
