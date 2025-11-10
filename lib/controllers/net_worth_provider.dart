import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';

import 'insights_provider.dart';

final totalAssetsProvider = FutureProvider.autoDispose<double>((ref) async {
  // Watch the provider to get its AsyncValue, then handle the states.
  final assetsAsync = ref.watch(assetListProvider);
  return assetsAsync.when(
    data: (assets) =>
        assets.fold<double>(0.0, (sum, asset) => sum + asset.value),
    loading: () => 0.0, // Return 0 while loading
    error: (e, s) => throw e, // Propagate error
  );
});

final totalLiabilitiesProvider =
    FutureProvider.autoDispose<double>((ref) async {
  // Watch the provider to get its AsyncValue, then handle the states.
  final emisAsync = ref.watch(emiListProvider);
  return emisAsync.when(
    data: (emis) => emis
        .where((emi) => emi.tenureRemainingMonths > 0)
        .fold<double>(
            0.0,
            (sum, emi) =>
                sum + (emi.monthlyEmiAmount * emi.tenureRemainingMonths)),
    loading: () => 0.0, // Return 0 while loading
    error: (e, s) => throw e, // Propagate error
  );
});

final netWorthProvider = FutureProvider.autoDispose<double>((ref) async {
  // Await the results of the dependent FutureProviders.
  // Riverpod will automatically manage the dependency chain.
  final totalAssets = await ref.watch(totalAssetsProvider.future);
  final totalLiabilities = await ref.watch(totalLiabilitiesProvider.future);
  return totalAssets - totalLiabilities;
});

final netWorthChangeProvider = FutureProvider.autoDispose<double>((ref) async {
  // Watch the asset list provider to get its AsyncValue
  final assetsAsync = ref.watch(assetListProvider);

  return assetsAsync.when(
    data: (assets) async {
      // 1. Calculate total monthly appreciation from all assets
      final totalMonthlyAppreciation = assets.fold<double>(0.0, (sum, asset) {
        if (asset.yearlyAppreciation != null && asset.yearlyAppreciation! > 0) {
          // Calculate monthly appreciation
          final monthlyRate = (asset.yearlyAppreciation! / 100) / 12;
          final monthlyGain = asset.value * monthlyRate;
          return sum + monthlyGain;
        }
        return sum;
      });

      // 2. Get total savings (investments) for the current month
      final spendingBreakdown =
          await ref.watch(spendingBreakdownProvider.future);
      final monthlySavings = spendingBreakdown.investments;

      return totalMonthlyAppreciation + monthlySavings;
    },
    loading: () => 0.0, // Return 0 while assets are loading
    error: (e, s) => throw e, // Propagate the error
  );
});
