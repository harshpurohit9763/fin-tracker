import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';
import 'package:offline_expense_tracker/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _NeedsVsWantsCard(),
          SizedBox(height: 24),
          _SubscriptionTrackerCard(),
          SizedBox(height: 24),
          _CashFlowProjectionCard(),
        ],
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
          return const Card(
            child: SizedBox(
              height: 200,
              child: Center(child: Text('No spending data for this period.')),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending Breakdown',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _buildPieChart(data),
                ),
                const SizedBox(height: 16),
                _BreakdownRow(
                    title: 'Needs',
                    amount: AppFormatters.formatCurrency(data.needs, currency),
                    percentage:
                        '${(data.needs / data.total * 100).toStringAsFixed(1)}%',
                    color: Colors.blue),
                _BreakdownRow(
                    title: 'Wants',
                    amount: AppFormatters.formatCurrency(data.wants, currency),
                    percentage:
                        '${(data.wants / data.total * 100).toStringAsFixed(1)}%',
                    color: Colors.purple),
                _BreakdownRow(
                    title: 'Investments',
                    amount: AppFormatters.formatCurrency(
                        data.investments, currency),
                    percentage:
                        '${(data.investments / data.total * 100).toStringAsFixed(1)}%',
                    color: Colors.green),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Card(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildPieChart(SpendingBreakdown data) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: data.needs,
            title: '${(data.needs / data.total * 100).toStringAsFixed(0)}%',
            color: Colors.blue,
            radius: 50,
          ),
          PieChartSectionData(
            value: data.wants,
            title: '${(data.wants / data.total * 100).toStringAsFixed(0)}%',
            color: Colors.purple,
            radius: 50,
          ),
          PieChartSectionData(
            value: data.investments,
            title:
                '${(data.investments / data.total * 100).toStringAsFixed(0)}%',
            color: Colors.green,
            radius: 50,
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
          Text(percentage, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(amount,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Card for tracking recurring bills and subscriptions.
class _SubscriptionTrackerCard extends StatelessWidget {
  const _SubscriptionTrackerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recurring Bills & Subscriptions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Total Monthly Cost: \$58.98',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            const ListTile(
              leading: Icon(Icons.movie_filter),
              title: Text('Netflix'),
              subtitle: Text('Next due: Oct 25, 2024'),
              trailing: Text('\$15.99'),
            ),
            const ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Spotify'),
              subtitle: Text('Next due: Oct 28, 2024'),
              trailing: Text('\$10.99'),
            ),
            const ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Gym Membership'),
              subtitle: Text('Next due: Nov 01, 2024'),
              trailing: Text('\$32.00'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for projecting cash flow.
class _CashFlowProjectionCard extends StatelessWidget {
  const _CashFlowProjectionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: const Text('Cash Flow Forecast Chart Placeholder'),
      ),
    );
  }
}
