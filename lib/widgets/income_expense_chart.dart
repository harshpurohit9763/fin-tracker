import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncomeExpenseChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const IncomeExpenseChart({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double maxY =
        (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String title;
                switch (group.x.toInt()) {
                  case 0:
                    title = 'Income';
                    break;
                  case 1:
                    title = 'Expense';
                    break;
                  default:
                    throw Error();
                }
                return BarTooltipItem(
                  '$title\n',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: rod.toY.toStringAsFixed(2),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
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
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Income';
                      break;
                    case 1:
                      text = 'Expense';
                      break;
                    default:
                      return Container();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            _buildBarGroup(0, totalIncome, Colors.green),
            _buildBarGroup(1, totalExpense, Colors.red),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
