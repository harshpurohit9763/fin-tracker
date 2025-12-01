import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/views/add_income_screen.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeListAsyncValue = ref.watch(filteredIncomeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Income'),
        actions: [
          // Month Dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<int>(
              value: ref.watch(selectedMonthYearProvider).month,
              items: List.generate(12, (index) => index + 1).map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(AppFormatters.getMonthName(month)),
                );
              }).toList(),
              onChanged: (month) {
                if (month != null) {
                  final currentSelection = ref.read(selectedMonthYearProvider);
                  ref.read(selectedMonthYearProvider.notifier).state =
                      DateTime(currentSelection.year, month);
                }
              },
              underline: Container(),
            ),
          ),
          const SizedBox(width: 10),
          // Year Dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButton<int>(
              value: ref.watch(selectedMonthYearProvider).year,
              items: List.generate(
                6, // Current year and 5 previous years
                (index) => DateTime.now().year - index,
              ).map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (year) {
                if (year != null) {
                  final currentSelection = ref.read(selectedMonthYearProvider);
                  ref.read(selectedMonthYearProvider.notifier).state =
                      DateTime(year, currentSelection.month);
                }
              },
              underline: Container(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: incomeListAsyncValue.when(
        data: (incomes) {
          if (incomes.isEmpty) {
            return const Center(
              child: Text('No income recorded for this month.'),
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
