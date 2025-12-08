import 'dart:ui'; // For Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/widgets/add_expense.dart';
import 'package:personal_finance/widgets/month_year_selector.dart';
import 'package:personal_finance/widgets/expense_list_item.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final expensesAsyncValue = ref.watch(filteredExpenseListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- 1. App Bar ---
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 100.0,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'All Expenses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- 2. List & Summary Card Logic ---
          expensesAsyncValue.when(
            data: (expenses) {
              // Calculate total even if empty (it will be 0.0)
              final totalExpense =
                  expenses.fold(0.0, (sum, item) => sum + item.amount);

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ------------------------------------------------
                      // ITEM 0: Always the Summary Card (with Filter)
                      // ------------------------------------------------
                      if (index == 0) {
                        return _buildSummaryCard(
                            context, totalExpense, currency, expenses.length);
                      }

                      // ------------------------------------------------
                      // ITEM 1 (If Empty): The Empty State Message
                      // ------------------------------------------------
                      if (expenses.isEmpty) {
                        // We use a Container with height to push it down visually
                        // acting like SliverFillRemaining but inside a list
                        return Container(
                          height: 400, // Arbitrary height to center visually
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 64,
                                  color: theme.disabledColor.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses found.',
                                style: TextStyle(
                                    fontSize: 18, color: theme.disabledColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Change the month above to see records.',
                                style: TextStyle(
                                    fontSize: 14, color: theme.disabledColor),
                              ),
                            ],
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // ITEMS 1+ (If Data): The Expense List Items
                      // ------------------------------------------------
                      final expense = expenses[index - 1]; // Adjust index
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ExpenseListItem(
                          expense: expense,
                          currency: currency,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddExpenseScreen(expense: expense),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    // If empty, count is 2 (Card + EmptyMsg). If data, count is N + 1 (Card + N items).
                    childCount: expenses.isEmpty ? 2 : expenses.length + 1,
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

      // --- 3. FAB ---
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
              MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("Add Expense",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Helper: Summary Card with Embedded Filter ---
  Widget _buildSummaryCard(
      BuildContext context, double total, String currency, int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE57373), // Soft Red/Orange for Expense
              const Color(0xFFEF5350).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE57373).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- CAPSULE DROPDOWN ---
                // This mimics the "This Month" look: White Text, Glass Background
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // The Glass Effect
                    borderRadius: BorderRadius.circular(18), // Fully Rounded
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  // We use SelectorPlacement.appBar because that usually
                  // forces the text color to be white/contrast
                  child: const Center(
                    child:
                        MonthYearSelector(placement: SelectorPlacement.appBar),
                  ),
                ),
                Icon(Icons.pie_chart_outline,
                    color: Colors.white.withOpacity(0.6)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              AppFormatters.formatCurrency(total, currency),
              style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              '$count transactions found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Delete Dialog ---
void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 48, color: Colors.redAccent),
              SizedBox(height: 16),
              Text('Delete Expense?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this expense record? This action cannot be undone.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
              onPressed: () {
                ref.read(expenseListProvider.notifier).deleteExpense(id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}
