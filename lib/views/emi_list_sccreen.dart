import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/views/add_emi_screen.dart'; // Ensure this matches your file structure
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

    // Neumorphic background color needs to be slightly off-white/grey for the effect to pop

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern Large Header ---
          SliverAppBar(
            // The AppBar will now use the theme's default scaffold color
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Loans & EMI',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // --- The List ---
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
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final emi = emis[index];
                      return _buildEmiCard(context, ref, emi);
                    },
                    childCount: emis.length,
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

  Widget _buildEmiCard(BuildContext context, WidgetRef ref, Emi emi) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final isPaidOff = emi.tenureRemainingMonths <= 0;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
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
              // Header: Icon + Name + Menu
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
                    icon: const Icon(Icons.check_rounded),
                    label: const Text("Mark as Paid"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
            Text(label, style: theme.textTheme.labelSmall),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // --- Dialogs ---

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delete Loan?', textAlign: TextAlign.center),
          content: const Text(
            'This will permanently remove this loan record from your dashboard.',
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
      // The standard AlertDialog will now use the app's theme.
      builder: (dialogContext) {
        // Glassmorphism Backdrop
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
                  'Confirm the amount paid for\n${emi.loanName}',
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
                  ),
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
                ),
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
