import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/controllers/goal_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/views/add_edit_goal_screen.dart';
import 'package:personal_finance/views/badges_screen.dart';
import 'package:personal_finance/views/goal_model.dart';

class FinancialGoalsScreen extends ConsumerWidget {
  const FinancialGoalsScreen({super.key});

  void _showContributeDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contribute to ${goal.name}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                // Pop the contribution dialog first
                Navigator.of(ctx).pop();

                final goalJustCompleted = await ref
                    .read(goalListProvider.notifier)
                    .contributeToGoal(goal, amount);

                if (goalJustCompleted) {
                  // Find the updated goal object to pass to the completion dialog
                  final updatedGoal = ref
                      .read(goalListProvider)
                      .value
                      ?.firstWhere((g) => g.id == goal.id);
                  if (updatedGoal != null && context.mounted) {
                    _showGoalCompletionDialog(context, updatedGoal);
                  }
                }
              }
            },
            child: const Text('Contribute'),
          ),
        ],
      ),
    );
  }

  void _showGoalCompletionDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Goal Achieved!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 80),
            const SizedBox(height: 16),
            const Text("Congratulations! You've reached your goal:"),
            const SizedBox(height: 8),
            Text(goal.name,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Awesome!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'My Achievements',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const BadgesScreen()),
              );
            },
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No goals yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the "+" button to add your first goal.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                goal: goal,
                currency: currency,
                onContribute: () => _showContributeDialog(context, ref, goal),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddEditGoalScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  final String currency;
  final VoidCallback onContribute;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.onContribute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = goal.isCompleted;
    final remaining = goal.targetAmount - goal.currentAmount;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      color: isCompleted
          ? Colors.green.shade500.withOpacity(0.15)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(goalIcons[goal.icon] ?? Icons.star,
                    size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => AddEditGoalScreen(goal: goal)));
                    } else if (value == 'delete') {
                      ref.read(goalListProvider.notifier).deleteGoal(goal.id!);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(goal.progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Target: ${AppFormatters.formatCurrency(goal.targetAmount, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      AppFormatters.formatCurrency(
                          goal.currentAmount, currency),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Remaining',
                        style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      AppFormatters.formatCurrency(
                          remaining > 0 ? remaining : 0, currency),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isCompleted ? null : onContribute,
                icon: Icon(isCompleted ? Icons.check_circle : Icons.add),
                label: Text(isCompleted ? 'Completed' : 'Contribute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
