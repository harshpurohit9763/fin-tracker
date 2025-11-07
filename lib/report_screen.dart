import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/category_pie_chart.dart';
import 'package:offline_expense_tracker/report_provider.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';
import 'package:offline_expense_tracker/weekly_trend_chart.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class ReportingScreen extends ConsumerWidget {
  const ReportingScreen({super.key});

  Future<void> _selectMonth(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(selectedMonthProvider);
    final picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      ref.read(selectedMonthProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final selectedDate = ref.watch(selectedMonthProvider);
    final selectedMonthString = DateFormat.yMMM().format(selectedDate);
    final totalAsync = ref.watch(selectedMonthTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          TextButton.icon(
            onPressed: () => _selectMonth(context, ref),
            icon: const Icon(Icons.calendar_today),
            label: Text(selectedMonthString),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Total Spending for $selectedMonthString',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    totalAsync.when(
                      data: (total) => Text(
                        AppFormatters.formatCurrency(total, currency),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, s) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Breakdown Pie Chart
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 300, child: CategoryPieChartWidget()),
            const SizedBox(height: 24),

            // Weekly Trend Line Chart
            Text(
              'Weekly Spending Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 300, child: WeeklyTrendChartWidget()),
          ],
        ),
      ),
    );
  }
}
