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
      height: 160, // Adjusted height for a more compact look
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: false, // Disable touch tooltip for simplicity, matching HTML
          ),
          titlesData: FlTitlesData(
            show: true,
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
                reservedSize: 20, // Reduced reserved space
                getTitlesWidget: (value, meta) {
                  String text;
                  Color textColor = theme.colorScheme.onSurfaceVariant;
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
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(text, style: TextStyle(color: textColor, fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false), // Remove border
          gridData: const FlGridData(show: false), // Remove grid lines
          barGroups: [
            _buildBarGroup(0, totalIncome, theme.colorScheme.primaryContainer), // Accent color for income
            _buildBarGroup(1, totalExpense, theme.colorScheme.error), // Error color for expense
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
          width: 24, // Adjusted width
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), // Rounded top
        ),
      ],
    );
  }
}
