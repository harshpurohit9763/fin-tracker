import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/views/add_emi_screen.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/emi_model.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class EmiListScreen extends ConsumerWidget {
  const EmiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emisAsyncValue = ref.watch(emiListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern Large Header ---
          // SliverAppBar(
          //   backgroundColor: theme.scaffoldBackgroundColor,
          //   expandedHeight: 120.0,
          //   floating: true,
          //   pinned: true,
          //   elevation: 0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          //     title: Text(
          //       'Loans & EMI',
          //       style: theme.textTheme.headlineSmall?.copyWith(
          //         fontWeight: FontWeight.w800,
          //       ),
          //     ),
          //   ),
          // ),
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
                'Loans & EMI',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // --- The List & Summary ---
          emisAsyncValue.when(
            data: (emis) {
              if (emis.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_score_rounded,
                            size: 64,
                            color: theme.disabledColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No active loans',
                          style: TextStyle(
                              fontSize: 18,
                              color: theme.disabledColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Calculate Totals
              final totalMonthlyLiability = emis.fold(0.0, (sum, item) {
                // Only count if not paid off
                return item.tenureRemainingMonths > 0
                    ? sum + item.monthlyEmiAmount
                    : sum;
              });

              final activeLoansCount =
                  emis.where((e) => e.tenureRemainingMonths > 0).length;

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // INDEX 0: Render the Total Summary Card
                      if (index == 0) {
                        return _buildTotalSummaryCard(context, theme,
                            totalMonthlyLiability, activeLoansCount, currency);
                      }

                      // INDEX > 0: Render the EMI Items
                      final emi = emis[index - 1]; // Offset index by 1
                      return _buildEmiCard(context, ref, emi);
                    },
                    // Add 1 to length to account for the Summary Card
                    childCount: emis.length + 1,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),

          // Bottom Spacer for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // --- Floating Action Button ---
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
          backgroundColor: theme.colorScheme.primary,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEmiScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("New Loan",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- NEW: Total Summary Card ---
  Widget _buildTotalSummaryCard(BuildContext context, ThemeData theme,
      double totalAmount, int activeCount, String currency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme
                  .tertiary, // Using tertiary for a nice gradient shift
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pie_chart_outline_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Monthly Liability',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppFormatters.formatCurrency(totalAmount, currency),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total across $activeCount active loans',
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

  Widget _buildEmiCard(BuildContext context, WidgetRef ref, Emi emi) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isPaidOff = emi.tenureRemainingMonths <= 0;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEmiScreen(emi: emi)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPaidOff
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isPaidOff
                          ? Icons.check_circle_outline_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: isPaidOff ? Colors.green : colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emi.loanName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (isPaidOff)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "PAID OFF",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(
                        emi.monthlyEmiAmount, currency),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Details: Due Date & Remaining Tenure
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(
                    theme,
                    isPaidOff ? 'Completed' : 'Next Due',
                    isPaidOff ? '-' : AppFormatters.formatDate(emi.nextDueDate),
                    isPaidOff ? Icons.flag_rounded : Icons.calendar_today,
                  ),
                  _buildDetailItem(
                    theme,
                    'Months Left',
                    '${emi.tenureRemainingMonths}',
                    Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),

              if (!isPaidOff) ...[
                const SizedBox(height: 20),
                // Mark as Paid Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(context, ref, emi),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text("Mark Paid"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 2),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // --- Dialogs (Same as before) ---

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delete Loan?', textAlign: TextAlign.center),
          content: const Text(
            'This will permanently remove this loan record.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(emiListProvider.notifier).deleteEmi(id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _markAsPaid(BuildContext context, WidgetRef ref, Emi emi) {
    final amountController =
        TextEditingController(text: emi.monthlyEmiAmount.toStringAsFixed(2));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Record Payment', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm amount for\n${emi.loanName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Amount Paid',
                      prefixText: '${ref.read(currencyProvider)} ',
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none)),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Confirm'),
                onPressed: () {
                  final paidAmount = double.tryParse(amountController.text);
                  if (paidAmount != null && paidAmount > 0) {
                    ref
                        .read(emiListProvider.notifier)
                        .markEmiAsPaidWithAmount(emi, paidAmount);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    ).then((_) => amountController.dispose());
  }
}
