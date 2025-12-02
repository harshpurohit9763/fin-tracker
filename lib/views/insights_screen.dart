import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/controllers/insights_provider.dart';
import 'package:personal_finance/widgets/cash_flow_chart.dart'; // Import the new cash flow chart

import 'manage_subscriptions_screen.dart';
import '../controllers/subscription_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32), // Top spacing
            Text(
              'Financial Insights',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            const _NeedsVsWantsCard(),
            const SizedBox(height: 24),
            const _SubscriptionTrackerCard(),
            const SizedBox(height: 24),
            const _CashFlowProjectionCard(),
          ],
        ),
      ),
    );
  }
}

/// Card for visualizing Needs vs. Wants vs. Savings.
class _NeedsVsWantsCard extends ConsumerWidget {
  const _NeedsVsWantsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(spendingBreakdownProvider);
    final currency = ref.watch(currencyProvider);

    return breakdownAsync.when(
      data: (data) {
        if (data.total == 0) {
          return Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SizedBox(
              height: 150,
              child: Center(
                  child: Text(
                'No spending data for this period.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spending Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: _buildPieChart(data, context),
              ),
              const SizedBox(height: 16),
              _BreakdownRow(
                  title: 'Needs',
                  amount: AppFormatters.formatCurrency(data.needs, currency),
                  percentage:
                      '${(data.needs / data.total * 100).toStringAsFixed(1)}%',
                  color: Theme.of(context).colorScheme.primary),
              _BreakdownRow(
                  title: 'Wants',
                  amount: AppFormatters.formatCurrency(data.wants, currency),
                  percentage:
                      '${(data.wants / data.total * 100).toStringAsFixed(1)}%',
                  color: Theme.of(context).colorScheme.secondary),
              _BreakdownRow(
                  title: 'Investments',
                  amount:
                      AppFormatters.formatCurrency(data.investments, currency),
                  percentage:
                      '${(data.investments / data.total * 100).toStringAsFixed(1)}%',
                  color: Theme.of(context).colorScheme.tertiary),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Container(
        height: 200,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
            child: Text(
          'Error: $e',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        )),
      ),
    );
  }

  Widget _buildPieChart(SpendingBreakdown data, BuildContext context) {
    final theme = Theme.of(context);
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: data.needs,
            title: '${(data.needs / data.total * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.primary, // Using primary accent color
            radius: 60, // Adjusted radius
            titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: data.wants,
            title: '${(data.wants / data.total * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.secondary, // Using secondary accent color
            radius: 60, // Adjusted radius
            titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: data.investments,
            title:
                '${(data.investments / data.total * 100).toStringAsFixed(0)}%',
            color: theme.colorScheme.tertiary, // Using tertiary accent color
            radius: 60, // Adjusted radius
            titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 3, // Adjusted sections space
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String title;
  final String amount;
  final String percentage;
  final Color color;

  const _BreakdownRow(
      {required this.title,
      required this.amount,
      required this.percentage,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )),
            ],
          ),
          Text(percentage, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          )),
        ],
      ),
    );
  }
}

/// Card for tracking recurring bills and subscriptions.
class _SubscriptionTrackerCard extends ConsumerWidget {
  const _SubscriptionTrackerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionListProvider);
    final currency = ref.watch(currencyProvider);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: subscriptionsAsync.when(
        data: (subs) {
          final totalMonthlyCost =
              subs.fold<double>(0.0, (sum, item) => sum + item.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recurring Bills',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          )),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ManageSubscriptionsScreen())),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary, // Accent color
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Manage'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Total Monthly Cost: ${AppFormatters.formatCurrency(totalMonthlyCost, currency)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 16),
              if (subs.isEmpty)
                Text('No subscriptions added.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ))
              else
                ...subs.map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  'Next due: ${AppFormatters.formatDate(sub.nextDueDate)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(sub.amount, currency),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    )),
            ],
          );
        },
        loading: () => Container(
          height: 200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Container(
          height: 200,
          child: Center(
              child: Text(
            'Error: $e',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          )),
        ),
      ),
    );
  }
}

/// Card for projecting cash flow.
class _CashFlowProjectionCard extends ConsumerWidget {
  const _CashFlowProjectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowDataProvider);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cash Flow',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
          const SizedBox(height: 16),
          cashFlowAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return SizedBox(
                  height: 150,
                  child: Center(
                      child: Text(
                          'Not enough data to display cash flow chart (min 2 months).',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ))),
                );
              }
              return CashFlowChart(cashFlowData: data);
            },
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SizedBox(
              height: 150,
              child: Center(
                  child: Text(
                'Error loading cash flow data: $e',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              )),
            ),
          ),
          const SizedBox(height: 16),
          // Legend for the chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendItem(color: Theme.of(context).colorScheme.primary, text: 'Income'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: Theme.of(context).colorScheme.error, text: 'Expenses'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: Theme.of(context).colorScheme.secondary, text: 'Net Flow'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _ChartLegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        )),
      ],
    );
  }
}
