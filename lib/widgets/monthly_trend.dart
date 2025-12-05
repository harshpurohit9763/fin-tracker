import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';

class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(last6MonthsSpendingProvider);
    final currentMonthSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final currency = ref.watch(currencyProvider);

    return spendingAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Not enough data to show trend.'));
        }

        // Calculate percentage change for the title, similar to HTML reference
        double percentageChange = 0.0;
        final spendingValues = data.values.toList();
        if (spendingValues.length >= 2) {
          final currentMonth = spendingValues.last;
          final previousMonth = spendingValues[spendingValues.length - 2];
          if (previousMonth != 0) {
            percentageChange = ((currentMonth - previousMonth) / previousMonth) * 100;
          }
        }
        
        // Determine the text color for percentage change based on accent color
        final accentColor = Theme.of(context).colorScheme.secondary; // Using secondary as a dynamic accent
        Color percentageColor = Colors.grey;
        IconData percentageIcon = Icons.trending_flat;

        if (percentageChange > 0) {
          percentageColor = Colors.red; // More spending is usually "bad"
          percentageIcon = Icons.trending_up;
        } else if (percentageChange < 0) {
          percentageColor = Colors.green; // Less spending is "good"
          percentageIcon = Icons.trending_down;
        }


        double maxY = 0;
        for (var entry in data.entries) {
          if (entry.value > maxY) maxY = entry.value;
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary, // Creamy background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  currentMonthSpendingAsync.when(
                    data: (total) => Text(
                      AppFormatters.formatCurrency(total, currency),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    loading: () => Text('...', style: Theme.of(context).textTheme.headlineMedium),
                    error: (e, s) => Text('Error', style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: percentageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(percentageIcon, size: 16, color: percentageColor),
                        const SizedBox(width: 4),
                        Text(
                          '${percentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: percentageColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Spending Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180, // Adjust chart height
                child: LineChart(
                  LineChartData(
                    maxY: maxY * 1.2, // Add 20% padding to top
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final month = data.keys.elementAt(spot.x.toInt());
                            return LineTooltipItem(
                              '$month\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: AppFormatters.formatCurrency(spot.y, currency),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
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
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.keys.length) {
                              return Container();
                            }
                            final monthYear = data.keys.elementAt(index);
                            final date = DateTime.parse('${monthYear}-01');
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat.MMM().format(date),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          strokeWidth: 0.5,
                          dashArray: [8, 4],
                        );
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                          spots: List.generate(data.length, (index) {
                            return FlSpot(index.toDouble(), data.values.elementAt(index));
                          }),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              Theme.of(context).colorScheme.primary.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
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
