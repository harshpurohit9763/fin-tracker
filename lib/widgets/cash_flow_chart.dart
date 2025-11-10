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
    final currency = ref.watch(currencyProvider);

    if (cashFlowData.isEmpty) {
      return const Center(
        child:
            Text('Not enough data to display cash flow chart (min 2 months).'),
      );
    }

    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expensesSpots = [];
    final List<FlSpot> netFlowSpots = [];

    double maxY = 0;
    double minY = 0;

    for (int i = 0; i < cashFlowData.length; i++) {
      final data = cashFlowData[i];
      incomeSpots.add(FlSpot(i.toDouble(), data.income));
      expensesSpots.add(FlSpot(i.toDouble(), data.expenses));
      netFlowSpots.add(FlSpot(i.toDouble(), data.netFlow));

      if (data.income > maxY) maxY = data.income;
      if (data.expenses > maxY) maxY = data.expenses;
      if (data.netFlow > maxY) maxY = data.netFlow;

      if (data.income < minY) minY = data.income;
      if (data.expenses < minY) minY = data.expenses;
      if (data.netFlow < minY) minY = data.netFlow;
    }

    // Add some padding to maxY and minY for better visualization
    maxY *= 1.1;
    minY *= 1.1;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (maxY - minY) / 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xff37434d),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < cashFlowData.length) {
                      final data = cashFlowData[index];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(
                          '${AppFormatters.monthAbbreviations[data.month - 1]} \'${data.year.toString().substring(2)}',
                          style: const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxY - minY) / 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      AppFormatters.formatCurrency(value, currency),
                      style: const TextStyle(
                        color: Color(0xff67727d),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: (cashFlowData.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                color: Colors.green,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: expensesSpots,
                isCurved: true,
                color: Colors.red,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: netFlowSpots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
