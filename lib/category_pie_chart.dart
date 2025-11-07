import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/report_provider.dart';

class CategoryPieChartWidget extends ConsumerWidget {
  const CategoryPieChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final totalAsync = ref.watch(selectedMonthTotalProvider);

    return breakdownAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No data for this month.'));
        }

        final double total =
            totalAsync.value ?? data.values.fold(0, (a, b) => a + b);

        // Generate pie chart sections
        final List<PieChartSectionData> sections = data.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0;
          return PieChartSectionData(
            color: Colors.primaries[data.keys.toList().indexOf(entry.key) %
                Colors.primaries.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          );
        }).toList();

        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.keys.map((key) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.primaries[
                        data.keys.toList().indexOf(key) %
                            Colors.primaries.length],
                  ),
                  label: Text(
                    '$key: ${AppFormatters.formatCurrency(data[key]!, 'INR')}',
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
