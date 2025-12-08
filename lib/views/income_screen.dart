import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/views/add_income_screen.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/widgets/month_year_selector.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH THE DATE PROVIDER: Critical for updating the list when filter changes
    final selectedDate = ref.watch(selectedMonthYearProvider);

    final incomeListAsyncValue = ref.watch(filteredIncomeListProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
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
                'My Income',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // --- List Logic ---
          incomeListAsyncValue.when(
            data: (incomes) {
              final totalIncome =
                  incomes.fold(0.0, (sum, item) => sum + item.amount);

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ---------------------------------------------
                      // INDEX 0: Summary Card (Green)
                      // ---------------------------------------------
                      if (index == 0) {
                        return _buildIncomeSummaryCard(
                            context, totalIncome, currency, incomes.length);
                      }

                      // ---------------------------------------------
                      // INDEX 1: Empty State
                      // ---------------------------------------------
                      if (incomes.isEmpty) {
                        return Container(
                          height: 400,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: theme.disabledColor.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No income recorded.',
                                style: TextStyle(
                                    fontSize: 18, color: theme.disabledColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select a different month above.',
                                style: TextStyle(
                                    fontSize: 14, color: theme.disabledColor),
                              ),
                            ],
                          ),
                        );
                      }

                      // ---------------------------------------------
                      // INDEX > 0: Income Items
                      // ---------------------------------------------
                      final income = incomes[index - 1];
                      final bool showMarkAsReceived = income.isMonthly;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: IncomeCard(
                          income: income,
                          showMarkAsReceived: showMarkAsReceived,
                          onMarkAsReceived: showMarkAsReceived
                              ? () =>
                                  _handleMarkAsReceived(context, ref, income)
                              : null,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddIncomeScreen(income: income),
                              ),
                            );
                          },
                          onDelete: () =>
                              _confirmDelete(context, ref, income.id!),
                        ),
                      );
                    },
                    childCount: incomes.isEmpty ? 2 : incomes.length + 1,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error'))),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // --- FAB ---
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
              MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("Add Income",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- Green Summary Card ---
  Widget _buildIncomeSummaryCard(
      BuildContext context, double total, String currency, int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF66BB6A), // Green 400
              const Color(0xFF43A047).withOpacity(0.9), // Green 600
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF66BB6A).withOpacity(0.4),
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
                // --- FILTER CAPSULE ---
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child:
                        MonthYearSelector(placement: SelectorPlacement.appBar),
                  ),
                ),
                Icon(Icons.trending_up_rounded,
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
              '$count sources found',
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

  // --- Logic Helpers ---
  void _handleMarkAsReceived(
      BuildContext context, WidgetRef ref, Income income) {
    final now = DateTime.now();
    final newIncomeDate = DateTime(now.year, now.month);

    final newIncome = Income(
      amount: income.amount,
      source: income.source,
      description: income.description,
      date: newIncomeDate,
      isMonthly: false,
      monthYear: AppFormatters.formatMonthYear(newIncomeDate),
    );

    ref.read(incomeListProvider.notifier).addIncome(newIncome);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Received ${income.description}"),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            title: const Text('Delete Income?'),
            content: const Text(
              'Are you sure you want to delete this income entry?',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
                child: const Text('Delete'),
                onPressed: () {
                  ref.read(incomeListProvider.notifier).deleteIncome(id);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
