import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/category_model.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/report_provider.dart';
import 'package:personal_finance/report_repo.dart'; // Import ReportRepository and CashFlowData

class SpendingBreakdown {
  final double needs;
  final double wants;
  final double investments;
  final double income;

  SpendingBreakdown(
      {this.needs = 0.0,
      this.wants = 0.0,
      this.investments = 0.0,
      this.income = 0.0});

  double get total => needs + wants + investments;
}

final spendingBreakdownProvider =
    FutureProvider.autoDispose<SpendingBreakdown>((ref) async {
  // Depend on these providers to auto-refresh when they change
  // Watch the categoryListProvider to get its AsyncValue state.
  final categoriesAsync = ref.watch(categoryListProvider);

  // Use .when to handle the different states of the async value.
  return categoriesAsync.when(
    data: (categories) async {
      final range = ref.watch(currentDateRangeProvider);
      final breakdown = await ref
          .watch(reportRepositoryProvider)
          .getCategoryBreakdown(range.start, range.end);
      final totalIncome = await ref
          .watch(reportRepositoryProvider)
          .getTotalIncomeForDateRange(range.start, range.end);

      double needsTotal = 0;
      double wantsTotal = 0;
      double investmentsTotal = 0;

      for (var entry in breakdown.entries) {
        final categoryName = entry.key;
        final amount = entry.value;
        final category = categories.firstWhere((c) => c.name == categoryName,
            orElse: () => Category(name: 'Unknown'));

        if (category.type == CategoryType.Need) needsTotal += amount;
        if (category.type == CategoryType.Want) wantsTotal += amount;
        if (category.type == CategoryType.Investment)
          investmentsTotal += amount;
      }

      return SpendingBreakdown(
          needs: needsTotal,
          wants: wantsTotal,
          investments: investmentsTotal,
          income: totalIncome);
    },
    // If categories are loading or have an error, the spending breakdown can't be calculated.
    loading: () =>
        SpendingBreakdown(), // Return an empty breakdown while loading
    error: (e, s) => throw e, // Propagate the error
  );
});

final cashFlowDataProvider =
    FutureProvider.autoDispose<List<CashFlowData>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();

  // Fetch data for the last 12 months to ensure enough data for at least 2 months
  final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
  final cashFlows = await repository.getMonthlyCashFlow(twelveMonthsAgo, now);

  // Filter out months with no data and ensure at least 2 months of data
  final filteredCashFlows =
      cashFlows.where((data) => data.income > 0 || data.expenses > 0).toList();

  if (filteredCashFlows.length < 2) {
    return []; // Not enough data to display the chart
  }

  return filteredCashFlows;
});
