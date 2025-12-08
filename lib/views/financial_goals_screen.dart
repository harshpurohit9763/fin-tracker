import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/controllers/goal_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/views/add_edit_goal_screen.dart';
import 'package:personal_finance/views/badges_screen.dart';
import 'package:personal_finance/views/goal_model.dart'; // Ensure path is correct based on your project

class FinancialGoalsScreen extends ConsumerWidget {
  const FinancialGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- 1. Modern Sliver App Bar ---
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_rounded,
                        color: theme.colorScheme.tertiary, size: 22),
                  ),
                  tooltip: 'Achievements',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const BadgesScreen()),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Financial Goals',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- 2. Goals List ---
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded,
                            size: 64,
                            color: theme.disabledColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No goals set yet.',
                          style: TextStyle(
                              fontSize: 18, color: theme.disabledColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to start saving for something.',
                          style: TextStyle(
                              fontSize: 14, color: theme.disabledColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
                      return _buildGoalCard(context, ref, goal, currency);
                    },
                    childCount: goals.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),

          // Bottom Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // --- 3. Gradient FAB ---
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const AddEditGoalScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("New Goal",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Premium Goal Card ---
  Widget _buildGoalCard(
      BuildContext context, WidgetRef ref, Goal goal, String currency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = goal.isCompleted;
    final progressColor =
        isCompleted ? Colors.green : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _showContributeDialog(context, ref, goal),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1)),
                width: isCompleted ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          goalIcons[goal.icon] ?? Icons.star_rounded,
                          color: progressColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCompleted)
                            Text(
                              "COMPLETED",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  _buildMenuButton(context, ref, goal),
                ],
              ),

              const SizedBox(height: 20),

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
                    widthFactor: goal.progress.clamp(0.0, 1.0),
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

              const SizedBox(height: 16),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatCurrency(
                            goal.currentAmount, currency),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatCurrency(
                            goal.targetAmount, currency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, WidgetRef ref, Goal goal) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: Theme.of(context).hintColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => AddEditGoalScreen(goal: goal)));
        } else if (value == 'delete') {
          ref.read(goalListProvider.notifier).deleteGoal(goal.id!);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 8),
            Text('Edit')
          ]),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.red))
          ]),
        ),
      ],
    );
  }

  // --- Glass Dialogs ---

  void _showContributeDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final amountController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Add Funds',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("To: ${goal.name}",
                  style: TextStyle(color: theme.hintColor)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.of(ctx).pop();
                  final goalJustCompleted = await ref
                      .read(goalListProvider.notifier)
                      .contributeToGoal(goal, amount);

                  if (goalJustCompleted) {
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
      ),
    );
  }

  void _showGoalCompletionDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                "Goal Achieved!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                "Congratulations! You've completed your goal:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 8),
              Text(
                goal.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Awesome!"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
