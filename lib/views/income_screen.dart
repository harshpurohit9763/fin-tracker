import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/income_model.dart';
import 'package:personal_finance/views/add_income_screen.dart';
import 'package:personal_finance/widgets/income_card.dart';
import 'package:personal_finance/controllers/income_provider.dart';

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
              return SliverMainAxisGroup(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final income = incomes[index];

                        // If an income is monthly, it's a template that hasn't been received for this month yet.
                        // The filtering logic in `filteredIncomeListProvider` ensures this.
                        final bool showMarkAsReceived = income.isMonthly;

                        return IncomeCard(
                          income: income,
                          showMarkAsReceived: showMarkAsReceived,
                          onMarkAsReceived: showMarkAsReceived
                              ? () {
                                  final now = DateTime.now();
                                  final newIncomeDate =
                                      DateTime(now.year, now.month);
                                  final newIncome = Income(
                                      amount: income.amount,
                                      source: income.source,
                                      description: income.description,
                                      date: newIncomeDate,
                                      isMonthly: false,
                                      monthYear: AppFormatters.formatMonthYear(
                                          newIncomeDate));
                                  ref
                                      .read(incomeListProvider.notifier)
                                      .addIncome(newIncome);
                                }
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
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80), // Space for the FAB
                  ),
                ],
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error'))),
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
