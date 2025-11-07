import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/add_emi_screen.dart';
import 'package:offline_expense_tracker/app_formater.dart';
import 'package:offline_expense_tracker/emi_model.dart';
import 'package:offline_expense_tracker/emi_provider.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';

class EmiListScreen extends ConsumerWidget {
  const EmiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emisAsyncValue = ref.watch(emiListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All EMIs & Loans')),
      body: emisAsyncValue.when(
        data: (emis) {
          if (emis.isEmpty) {
            return const Center(
              child: Text(
                'No EMIs added yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: emis.length,
            itemBuilder: (context, index) {
              final emi = emis[index];
              final isPaidOff = emi.tenureRemainingMonths <= 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isPaidOff
                    ? Colors.green.withOpacity(0.1)
                    : Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          emi.loanName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                              builder: (context) => AddEmiScreen(emi: emi),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPaidOff
                                      ? 'PAID OFF'
                                      : 'Next Due: ${AppFormatters.formatDate(emi.nextDueDate)}',
                                  style: TextStyle(
                                    color: isPaidOff
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
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
                                onPressed: () => _markAsPaid(context, ref, emi),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Mark as Paid?'),
          content: Text(
            'Mark ${emi.loanName} as paid for this month? This will reduce the remaining tenure and set the next due date.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                ref.read(emiListProvider.notifier).markEmiAsPaid(emi);
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
}
