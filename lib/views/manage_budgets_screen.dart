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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budgets'),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets set for this month.'));
          }
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return ListTile(
                title: Text(budget.categoryName),
                trailing:
                    Text(AppFormatters.formatCurrency(budget.amount, currency)),
                onTap: () =>
                    _showAddEditBudgetDialog(context, ref, budget: budget),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBudgetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditBudgetDialog(BuildContext context, WidgetRef ref,
      {Budget? budget}) {
    final formKey = GlobalKey<FormState>();
    Category? selectedCategory;
    final amountController =
        TextEditingController(text: budget?.amount.toString());
    final bool isEditing = budget != null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
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
                            filled: isEditing,
                            fillColor: isEditing ? Colors.grey.shade800 : null,
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => const Text('Could not load categories'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Budget Amount'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
        );
      },
    );
  }
}
