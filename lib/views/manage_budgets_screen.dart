import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/budget_model.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/models/category_model.dart';
import 'package:personal_finance/controllers/category_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class ManageBudgetsScreen extends ConsumerWidget {
  const ManageBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final budgetsAsync = ref.watch(budgetListProvider);
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
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Manage Budgets',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- 2. Budget List ---
          budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded,
                            size: 64,
                            color: theme.disabledColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No budgets set.',
                          style: TextStyle(
                              fontSize: 18, color: theme.disabledColor),
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
                      final budget = budgets[index];
                      return _buildBudgetCard(context, ref, budget, currency);
                    },
                    childCount: budgets.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),

          // Bottom Spacer for FAB
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
          onPressed: () => _showAddEditBudgetDialog(context, ref),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("Add Budget",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Premium Card Widget ---
  Widget _buildBudgetCard(
      BuildContext context, WidgetRef ref, Budget budget, String currency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => _showAddEditBudgetDialog(context, ref, budget: budget),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.category_rounded,
                    color: theme.colorScheme.secondary, size: 24),
              ),
              const SizedBox(width: 16),

              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly Limit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Edit Icon
              Row(
                children: [
                  Text(
                    AppFormatters.formatCurrency(budget.amount, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded,
                      size: 16, color: theme.hintColor.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modern Dialog ---
  void _showAddEditBudgetDialog(BuildContext context, WidgetRef ref,
      {Budget? budget}) {
    final formKey = GlobalKey<FormState>();
    Category? selectedCategory;
    final amountController =
        TextEditingController(text: budget?.amount.toString());
    final bool isEditing = budget != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              isEditing ? 'Edit Budget' : 'Set Budget',
              style: const TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final categoriesAsync = ref.watch(categoryListProvider);
                      return categoriesAsync.when(
                        data: (categories) {
                          if (isEditing && selectedCategory == null) {
                            selectedCategory = categories.firstWhere(
                                (c) => c.name == budget.categoryName,
                                orElse: () => categories.first);
                          }
                          return DropdownButtonFormField<Category>(
                            value: selectedCategory,
                            hint: const Text('Select Category'),
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor:
                                isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            items: categories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c.name)))
                                .toList(),
                            onChanged: isEditing
                                ? null // Don't allow changing category when editing
                                : (value) => selectedCategory = value,
                            validator: (value) => value == null && !isEditing
                                ? 'Please select a category'
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.withOpacity(0.1),
                              prefixIcon: Icon(Icons.category_rounded,
                                  color: theme.colorScheme.primary),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                              enabled: !isEditing,
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) =>
                            const Text('Could not load categories'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monthly Limit',
                      prefixIcon: Icon(Icons.attach_money_rounded,
                          color: theme.colorScheme.primary),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white10
                          : Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding:
                const EdgeInsets.only(bottom: 24, left: 24, right: 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newBudget = Budget(
                      id: budget?.id,
                      categoryName: selectedCategory!.name,
                      amount: double.parse(amountController.text),
                      monthYear: AppFormatters.formatMonthYear(DateTime.now()),
                    );
                    await ref
                        .read(budgetRepositoryProvider)
                        .upsertBudget(newBudget);
                    ref.invalidate(budgetListProvider);
                    ref.invalidate(overallBudgetProvider);
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
