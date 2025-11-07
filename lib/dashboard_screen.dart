import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/add_expense.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/category_provider.dart';
import 'package:offline_expense_tracker/dashboard_provider.dart';
import 'package:offline_expense_tracker/emi_provider.dart';
import 'package:offline_expense_tracker/matteric_card.dart';
import 'package:offline_expense_tracker/monthly_trend.dart';
import 'package:offline_expense_tracker/upcomming_emi.dart';
import 'package:offline_expense_tracker/profile_screen.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    // Watch providers for the metric cards
    final totalSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final upcomingEmisAsync = ref.watch(upcomingEmisThisWeekCountProvider);

    // Refresh dashboard when expense or EMI lists change
    ref.watch(expenseListProvider);
    ref.watch(emiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning, User!'),
        actions: [
          IconButton(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all dashboard providers to refresh
          ref.invalidate(currentMonthSpendingProvider);
          ref.invalidate(upcomingEmisThisWeekCountProvider);
          ref.invalidate(last6MonthsSpendingProvider);
          ref.invalidate(next3UpcomingEmisProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Key Metrics Cards
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: totalSpendingAsync.when(
                          data: (total) => MetricCard(
                            title: "This Month's Spending",
                            value:
                                AppFormatters.formatCurrency(total, currency),
                            icon: Icons.show_chart,
                            color: Colors.green,
                          ),
                          loading: () => const MetricCard(
                            title: "This Month's Spending",
                            value: '...',
                            icon: Icons.show_chart,
                            color: Colors.green,
                          ),
                          error: (e, s) => const MetricCard(
                            title: "This Month's Spending",
                            value: 'Error',
                            icon: Icons.error,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: upcomingEmisAsync.when(
                          data: (count) => MetricCard(
                            title: 'EMIs Due This Week',
                            value: '$count Payments',
                            icon: Icons.payment,
                            color: Colors.orange,
                          ),
                          loading: () => const MetricCard(
                            title: 'EMIs Due This Week',
                            value: '...',
                            icon: Icons.payment,
                            color: Colors.orange,
                          ),
                          error: (e, s) => const MetricCard(
                            title: 'EMIs Due This Week',
                            value: 'Error',
                            icon: Icons.error,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      totalSpendingAsync.when(
                        data: (total) => MetricCard(
                          title: "This Month's Spending",
                          value: AppFormatters.formatCurrency(total, currency),
                          icon: Icons.show_chart,
                          color: Colors.green,
                        ),
                        loading: () => const MetricCard(
                          title: "This Month's Spending",
                          value: '...',
                          icon: Icons.show_chart,
                          color: Colors.green,
                        ),
                        error: (e, s) => const MetricCard(
                          title: "This Month's Spending",
                          value: 'Error',
                          icon: Icons.error,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      upcomingEmisAsync.when(
                        data: (count) => MetricCard(
                          title: 'EMIs Due This Week',
                          value: '$count Payments',
                          icon: Icons.payment,
                          color: Colors.orange,
                        ),
                        loading: () => const MetricCard(
                          title: 'EMIs Due This Week',
                          value: '...',
                          icon: Icons.payment,
                          color: Colors.orange,
                        ),
                        error: (e, s) => const MetricCard(
                          title: 'EMIs Due This Week',
                          value: 'Error',
                          icon: Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Monthly Trend Bar Chart
            Text(
              'Monthly Spending Trend (Last 6 Months)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 250,
              child: MonthlyTrendChart(),
            ),
            const SizedBox(height: 24),

            // EMI Due Panel
            Text(
              'Upcoming EMI Payments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const UpcomingEmiPanel(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
