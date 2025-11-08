import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/add_income_screen.dart';
import 'package:personal_finance/income_card.dart';
import 'package:personal_finance/income_provider.dart';
import 'package:personal_finance/income_model.dart'; // Import Income model

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeListAsyncValue = ref.watch(incomeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: incomeListAsyncValue.when(
        data: (incomes) {
          if (incomes.isEmpty) {
            return const Center(
              child: Text('No income recorded yet. Add your first income!'),
            );
          }
          return ListView.builder(
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index];
              return IncomeCard(
                income: income,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddIncomeScreen(income: income),
                    ),
                  );
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                            'Are you sure you want to delete this income entry?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Dismiss the dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(incomeListProvider.notifier)
                                  .deleteIncome(income.id!);
                              Navigator.of(context).pop(); // Dismiss the dialog
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
