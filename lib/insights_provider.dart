import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/category_model.dart';
import 'package:personal_finance/category_provider.dart';
import 'package:personal_finance/report_provider.dart';

class SpendingBreakdown {
  final double needs;
  final double wants;
  final double investments;

  SpendingBreakdown(
      {this.needs = 0.0, this.wants = 0.0, this.investments = 0.0});

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
          needs: needsTotal, wants: wantsTotal, investments: investmentsTotal);
    },
    // If categories are loading or have an error, the spending breakdown can't be calculated.
    loading: () =>
        SpendingBreakdown(), // Return an empty breakdown while loading
    error: (e, s) => throw e, // Propagate the error
  );
});
