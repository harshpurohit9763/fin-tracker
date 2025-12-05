import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/views/add_income_screen.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/widgets/month_year_selector.dart';
import 'package:personal_finance/widgets/selected_month_year_provider.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeListAsyncValue = ref.watch(filteredIncomeListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Monthly Income'),
            floating: true,
            snap: true,
            actions: const [
              // Use the new widget in the AppBar
              MonthYearSelector(placement: SelectorPlacement.appBar),
              SizedBox(width: 10), // Maintain original spacing
            ],
          ),
          incomeListAsyncValue.when(
            data: (incomes) {
              if (incomes.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No income recorded for this month.'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final income = incomes[index];
                    return IncomeCard(
                      income: income,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddIncomeScreen(income: income),
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
                                    Navigator.of(context)
                                        .pop(); // Dismiss the dialog
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(incomeListProvider.notifier)
                                        .deleteIncome(income.id!);
                                    Navigator.of(context)
                                        .pop(); // Dismiss the dialog
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
                  childCount: incomes.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (error, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $error'))),
          ),
        ],
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
