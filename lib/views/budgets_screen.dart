import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/budget_model.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/views/manage_budgets_screen.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBudgetsAsync = ref.watch(budgetListProvider);
    final overallBudgetAsync = ref.watch(overallBudgetProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
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

    return _SoftCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Monthly Budget',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _NeomorphicProgressIndicator(
            percentage: percentage,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spent', style: Theme.of(context).textTheme.bodySmall),
                  Text(AppFormatters.formatCurrency(spent, currency),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Remaining',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    AppFormatters.formatCurrency(remaining, currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: remaining >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A smaller card for tracking a single category's budget.
class _CategoryBudgetCard extends StatelessWidget {
  final Budget budget;

  const _CategoryBudgetCard({required this.budget});

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
          final percentage = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
          return _SoftCard(
            margin: const EdgeInsets.only(bottom: 12),
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
                _NeomorphicProgressIndicator(
                  percentage: percentage,
                  color: _getProgressColor(percentage),
                  height: 10,
                ),
              ],
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

class _NeomorphicProgressIndicator extends StatelessWidget {
  final double percentage;
  final Color color;
  final double height;

  const _NeomorphicProgressIndicator({
    required this.percentage,
    required this.color,
    this.height = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lightShadow = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Color.lerp(backgroundColor, Colors.black, 0.1)!;
    final darkShadow = isDarkMode
        ? Colors.black.withOpacity(0.5)
        : Color.lerp(backgroundColor, Colors.white, 0.9)!;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          // Inset shadow
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: darkShadow,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: FractionallySizedBox(
          widthFactor: percentage,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable neomorphic card.
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const _SoftCard({required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final lightShadow = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Color.lerp(backgroundColor, Colors.white, 0.7)!;
    final darkShadow = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Color.lerp(backgroundColor, Colors.black, 0.1)!;

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            offset: const Offset(4, 4),
            blurRadius: 15,
          ),
          BoxShadow(
            color: lightShadow,
            offset: const Offset(-4, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: child,
    );
  }
}
