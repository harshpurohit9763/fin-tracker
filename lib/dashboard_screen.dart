import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/add_expense.dart';
import 'package:offline_expense_tracker/advanced_reports_screen.dart';
import 'package:offline_expense_tracker/budgets_screen.dart';
import 'package:offline_expense_tracker/insights_screen.dart';
import 'package:offline_expense_tracker/net_worth_screen.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/category_provider.dart';
import 'package:offline_expense_tracker/dashboard_provider.dart';
import 'package:offline_expense_tracker/emi_provider.dart';
import 'package:offline_expense_tracker/matteric_card.dart';
import 'package:offline_expense_tracker/monthly_trend.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';
import 'package:offline_expense_tracker/upcomming_emi.dart';
import 'package:offline_expense_tracker/profile_screen.dart';

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final userName = ref.watch(userNameProvider);
    // Watch providers for the metric cards
    final totalSpendingAsync = ref.watch(currentMonthSpendingProvider);
    final upcomingEmisAsync = ref.watch(upcomingEmisThisWeekCountProvider);

    // Refresh dashboard when expense or EMI lists change
    ref.watch(expenseListProvider);
    ref.watch(emiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getGreeting()}, $userName!'),
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
          // Add extra padding at the bottom to avoid FAB overlap
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
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
                            value: AppFormatters.formatCurrency(
                              total,
                              currency,
                            ),
                            icon: Icons.show_chart,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          loading: () => const MetricCard(
                            title: "This Month's Spending",
                            value: '...',
                            icon: Icons.show_chart,
                            color: Colors.grey,
                          ),
                          error: (e, s) => const MetricCard(
                            title: "This Month's Spending",
                            value: 'Error',
                            icon: Icons.error,
                            color: Colors.redAccent,
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
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          loading: () => const MetricCard(
                            title: 'EMIs Due This Week',
                            value: '...',
                            icon: Icons.payment,
                            color: Colors.grey,
                          ),
                          error: (e, s) => const MetricCard(
                            title: 'EMIs Due This Week',
                            value: 'Error',
                            icon: Icons.error,
                            color: Colors.redAccent,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        loading: () => const MetricCard(
                          title: "This Month's Spending",
                          value: '...',
                          icon: Icons.show_chart,
                          color: Colors.grey,
                        ),
                        error: (e, s) => const MetricCard(
                          title: "This Month's Spending",
                          value: 'Error',
                          icon: Icons.error,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      upcomingEmisAsync.when(
                        data: (count) => MetricCard(
                          title: 'EMIs Due This Week',
                          value: '$count Payments',
                          icon: Icons.payment,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        loading: () => const MetricCard(
                          title: 'EMIs Due This Week',
                          value: '...',
                          icon: Icons.payment,
                          color: Colors.grey,
                        ),
                        error: (e, s) => const MetricCard(
                          title: 'EMIs Due This Week',
                          value: 'Error',
                          icon: Icons.error,
                          color: Colors.redAccent,
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
            const SizedBox(height: 250, child: MonthlyTrendChart()),
            const SizedBox(height: 24),

            // EMI Due Panel
            Text(
              'Upcoming EMI Payments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const UpcomingEmiPanel(),
            const SizedBox(height: 24),

            // Financial Tools Grid
            Text(
              'Financial Tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _FeatureTile(
                  title: 'Budgets',
                  icon: Icons.track_changes_outlined,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BudgetsScreen())),
                ),
                _FeatureTile(
                  title: 'Insights',
                  icon: Icons.lightbulb_outline,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InsightsScreen())),
                ),
                _FeatureTile(
                  title: 'Net Worth',
                  icon: Icons.assessment_outlined,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NetWorthScreen())),
                ),
                _FeatureTile(
                  title: 'Reports',
                  icon: Icons.analytics_outlined,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdvancedReportsScreen())),
                ),
              ],
            ),
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

/// A tappable card for navigating to a feature screen.
class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _FeatureTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
