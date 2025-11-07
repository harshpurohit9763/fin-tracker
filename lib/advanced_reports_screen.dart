import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main screen for displaying advanced, filterable reports.
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Report',
            onPressed: () {
              // Placeholder for export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // 1. Master Filter Bar
          _FilterBar(),
          SizedBox(height: 24),

          // 2. Report Widgets (Cards)
          _IncomeVsExpenseCard(),
          SizedBox(height: 24),

          _CategoryBreakdownCard(),
          SizedBox(height: 24),

          _TimeComparisonCard(),
          SizedBox(height: 24),

          _TransactionListCard(),
        ],
      ),
    );
  }
}

/// A bar with dropdowns to filter all reports on the screen.
class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Date Range and Account Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'This Month',
                    items: ['This Month', 'Last 3 Months', 'Custom']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: UnderlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'All Accounts',
                    // Placeholder: Accounts model needs to be created
                    items: ['All Accounts', 'Checking']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                        labelText: 'Account', border: UnderlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category Filter
            TextButton.icon(
              onPressed: () {
                // Placeholder for multi-select category dialog
              },
              icon: const Icon(Icons.category_outlined),
              label: const Text('Filter by Category'),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Card for Income vs. Expense trend chart.
class _IncomeVsExpenseCard extends StatelessWidget {
  const _IncomeVsExpenseCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs. Expense',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // Placeholder for Net Savings
            Text('Net Savings: \$1,248.50',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Placeholder for the chart
            Container(
                height: 200,
                alignment: Alignment.center,
                child: const Text('Line/Bar Chart Placeholder')),
          ],
        ),
      ),
    );
  }
}

/// Card for Expense Category Breakdown donut chart.
class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Breakdown',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Placeholder for the chart and list
            Container(
                height: 200,
                alignment: Alignment.center,
                child: const Text('Donut Chart & Category List Placeholder')),
          ],
        ),
      ),
    );
  }
}

/// Card for Monthly/Weekly spending comparison.
class _TimeComparisonCard extends StatelessWidget {
  const _TimeComparisonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Comparison',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Placeholder for the chart
            Container(
                height: 200,
                alignment: Alignment.center,
                child: const Text('Bar Chart Placeholder')),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying a detailed list of transactions.
class _TransactionListCard extends StatelessWidget {
  const _TransactionListCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Placeholder for the table
            Container(
                height: 300,
                alignment: Alignment.center,
                child: const Text('Scrollable Transaction Table Placeholder')),
          ],
        ),
      ),
    );
  }
}
