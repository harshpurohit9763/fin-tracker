import 'dart:ui';
import 'package:intl/intl.dart'; // Added import for DateFormat if needed later, good practice.
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('All EMIs & Loans'),
            floating: true,
            snap: true,
          ),
          emisAsyncValue.when(
            data: (emis) {
              if (emis.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No EMIs added yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final emi = emis[index];
                    final isPaidOff = emi.tenureRemainingMonths <= 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: isPaidOff // Use a subtle color from the theme
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3)
                          : Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                emi.loanName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${AppFormatters.formatCurrency(emi.monthlyEmiAmount, ref.watch(currencyProvider))} / month',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, ref, emi.id!),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEmiScreen(emi: emi),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPaidOff
                                            ? 'PAID OFF'
                                            : 'Next Due: ${AppFormatters.formatDate(emi.nextDueDate)}',
                                        style: TextStyle(
                                          color: isPaidOff // Use a more vibrant, theme-based color
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${emi.tenureRemainingMonths} months remaining',
                                      ),
                                    ],
                                  ),
                                  if (!isPaidOff)
                                    ElevatedButton(
                                      onPressed: () =>
                                          _markAsPaid(context, ref, emi),
                                      child: const Text('Mark as Paid'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: emis.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEmiScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete EMI?'),
          content: const Text(
            'Are you sure you want to delete this EMI record?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                ref.read(emiListProvider.notifier).deleteEmi(id);
                // Invalidate dashboard providers
                // ref.invalidate(dashboardMetricsProvider);
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.grey[900]?.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            title: const Text(
              'Confirm EMI Payment',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the amount paid for ${emi.loanName}.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4BEE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  final paidAmount = double.tryParse(amountController.text);
                  if (paidAmount != null && paidAmount > 0) {
                    ref
                        .read(emiListProvider.notifier)
                        .markEmiAsPaidWithAmount(emi, paidAmount);
                    Navigator.of(dialogContext).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid amount')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    ).then((_) => amountController.dispose()); // Dispose the controller when the dialog is closed.
  }
}

