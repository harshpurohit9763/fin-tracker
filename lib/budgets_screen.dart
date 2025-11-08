import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/budget_model.dart';
import 'package:personal_finance/budget_provider.dart';
import 'package:personal_finance/manage_budgets_screen.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBudgetsAsync = ref.watch(budgetListProvider);
    final overallBudgetAsync = ref.watch(overallBudgetProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Manage Budgets',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageBudgetsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          overallBudgetAsync.when(
            data: (data) => _OverallBudgetCard(
                spent: data['spent']!,
                total: data['total']!,
                currency: currency),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text('Error loading overall budget'),
          ),
          const SizedBox(height: 24),
          Text(
            'Category Budgets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          categoryBudgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) {
                return const Text('No category budgets set for this month.');
              }
              return Column(
                children: budgets
                    .map((budget) => _CategoryBudgetCard(budget: budget))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text('Error loading budgets'),
          ),
        ],
      ),
    );
  }
}

/// A card showing the overall monthly budget status.
class _OverallBudgetCard extends StatelessWidget {
  final double spent;
  final double total;
  final String currency;

  const _OverallBudgetCard(
      {required this.spent, required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    final remaining = total - spent;
    final percentage = total > 0 ? spent / total : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Monthly Budget',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 20,
                backgroundColor: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      'Spent: ${AppFormatters.formatCurrency(spent, currency)}/${AppFormatters.formatCurrency(total, currency)}'),
                ),
                Expanded(
                  child: Text(
                    'Remaining: ${AppFormatters.formatCurrency(remaining, currency)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color: remaining > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A smaller card for tracking a single category's budget.
class _CategoryBudgetCard extends StatelessWidget {
  final Budget budget;

  const _CategoryBudgetCard({super.key, required this.budget});

  Color _getProgressColor(double percentage) {
    if (percentage > 1.0) return Colors.red.shade700;
    if (percentage > 0.8) return Colors.orange.shade700;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final spentAsync =
          ref.watch(categorySpendingProvider(budget.categoryName));
      final currency = ref.watch(currencyProvider);
      return spentAsync.when(
        data: (spent) {
          final total = budget.amount;
          final percentage = total > 0 ? spent / total : 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget.categoryName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${AppFormatters.formatCurrency(spent, currency)} / ${AppFormatters.formatCurrency(total, currency)}'),
                      Text('${(percentage * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade700,
                      color: _getProgressColor(percentage),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text('Error: $e'),
      );
    });
  }
}
