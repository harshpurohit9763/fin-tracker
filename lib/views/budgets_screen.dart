// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:personal_finance/helper/app_formater.dart';
// import 'package:personal_finance/models/budget_model.dart';
// import 'package:personal_finance/controllers/budget_provider.dart';
// import 'package:personal_finance/views/manage_budgets_screen.dart';
// import 'package:personal_finance/controllers/shared_preferences_provider.dart';

// class BudgetsScreen extends ConsumerWidget {
//   const BudgetsScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final categoryBudgetsAsync = ref.watch(budgetListProvider);
//     final overallBudgetAsync = ref.watch(overallBudgetProvider);
//     final currency = ref.watch(currencyProvider);

//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         leading: CupertinoNavigationBarBackButton(
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text('Budgets'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_circle_outline),
//             tooltip: 'Manage Budgets',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => const ManageBudgetsScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           overallBudgetAsync.when(
//             data: (data) => _OverallBudgetCard(
//                 spent: data['spent']!,
//                 total: data['total']!,
//                 currency: currency),
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, s) => const Text('Error loading overall budget'),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'Category Budgets',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 8),
//           categoryBudgetsAsync.when(
//             data: (budgets) {
//               if (budgets.isEmpty) {
//                 return const Text('No category budgets set for this month.');
//               }
//               return Column(
//                 children: budgets
//                     .map((budget) => _CategoryBudgetCard(budget: budget))
//                     .toList(),
//               );
//             },
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (e, s) => const Text('Error loading budgets'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A card showing the overall monthly budget status.
// class _OverallBudgetCard extends StatelessWidget {
//   final double spent;
//   final double total;
//   final String currency;

//   const _OverallBudgetCard(
//       {required this.spent, required this.total, required this.currency});

//   @override
//   Widget build(BuildContext context) {
//     final remaining = total - spent;
//     final percentage = total > 0 ? spent / total : 0.0;

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Total Monthly Budget',
//                 style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 16),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: LinearProgressIndicator(
//                 value: percentage,
//                 minHeight: 20,
//                 backgroundColor: Colors.grey.shade700,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                       'Spent: ${AppFormatters.formatCurrency(spent, currency)}/${AppFormatters.formatCurrency(total, currency)}'),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'Remaining: ${AppFormatters.formatCurrency(remaining, currency)}',
//                     textAlign: TextAlign.end,
//                     style: TextStyle(
//                         color: remaining > 0 ? Colors.green : Colors.red,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// A smaller card for tracking a single category's budget.
// class _CategoryBudgetCard extends StatelessWidget {
//   final Budget budget;

//   const _CategoryBudgetCard({super.key, required this.budget});

//   Color _getProgressColor(double percentage) {
//     if (percentage > 1.0) return Colors.red.shade700;
//     if (percentage > 0.8) return Colors.orange.shade700;
//     return Colors.teal;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer(builder: (context, ref, _) {
//       final spentAsync =
//           ref.watch(categorySpendingProvider(budget.categoryName));
//       final currency = ref.watch(currencyProvider);
//       return spentAsync.when(
//         data: (spent) {
//           final total = budget.amount;
//           final percentage = total > 0 ? spent / total : 0.0;
//           return Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(budget.categoryName,
//                       style: Theme.of(context).textTheme.titleMedium),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                           '${AppFormatters.formatCurrency(spent, currency)} / ${AppFormatters.formatCurrency(total, currency)}'),
//                       Text('${(percentage * 100).toStringAsFixed(0)}%'),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: LinearProgressIndicator(
//                       value: percentage,
//                       minHeight: 10,
//                       backgroundColor: Colors.grey.shade700,
//                       color: _getProgressColor(percentage),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//         loading: () => const Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Center(child: CircularProgressIndicator()),
//         ),
//         error: (e, s) => Text('Error: $e'),
//       );
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is added to pubspec.yaml
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern App Bar ---
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'My Budgets',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- Overall Budget Hero ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: overallBudgetAsync.when(
                data: (data) => _OverallBudgetCard(
                  spent: data['spent']!,
                  total: data['total']!,
                  currency: currency,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // --- Category List ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  "Categories",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                categoryBudgetsAsync.when(
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'No budgets set. Tap + to create one.',
                            style: TextStyle(color: theme.disabledColor),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: budgets
                          .map((budget) => _CategoryBudgetCard(budget: budget))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading budgets: $e'),
                ),
                const SizedBox(height: 80), // Padding for FAB
              ]),
            ),
          ),
        ],
      ),

      // --- Gradient FAB ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ManageBudgetsScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("Set Budget",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

/// A premium gradient card showing the overall monthly budget status with a Donut chart.
class _OverallBudgetCard extends StatelessWidget {
  final double spent;
  final double total;
  final String currency;

  const _OverallBudgetCard(
      {required this.spent, required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    final remaining = total - spent;
    final percentage = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Text Data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Monthly Limit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppFormatters.formatCurrency(remaining, currency),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                Text(
                  'Remaining',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'of ${AppFormatters.formatCurrency(total, currency)} total',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Right: Donut Chart
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: percentage,
                        color: Colors.white,
                        radius: 10,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 1 - percentage,
                        color: Colors.black.withOpacity(0.1),
                        radius: 10,
                        showTitle: false,
                      ),
                    ],
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 35,
                  ),
                ),
                Text(
                  "${(percentage * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A "Soft UI" card for tracking a single category's budget.
class _CategoryBudgetCard extends StatelessWidget {
  final Budget budget;

  const _CategoryBudgetCard({super.key, required this.budget});

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.redAccent;
    if (percentage > 0.8) return Colors.orangeAccent;
    return Colors.greenAccent.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer(builder: (context, ref, _) {
      final spentAsync =
          ref.watch(categorySpendingProvider(budget.categoryName));
      final currency = ref.watch(currencyProvider);

      return spentAsync.when(
        data: (spent) {
          final total = budget.amount;
          final percentage = total > 0 ? (spent / total) : 0.0;
          final clampedPercentage = percentage.clamp(0.0, 1.0);
          final progressColor = _getProgressColor(percentage);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Dynamic dot color based on health
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: progressColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          budget.categoryName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${(percentage * 100).toInt()}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: clampedPercentage,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: progressColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${AppFormatters.formatCurrency(spent, currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    Text(
                      'Limit: ${AppFormatters.formatCurrency(total, currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text('Error: $e'),
      );
    });
  }
}
