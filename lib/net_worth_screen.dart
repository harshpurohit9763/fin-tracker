import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/asset_provider.dart';
import 'package:personal_finance/emi_provider.dart';
import 'package:personal_finance/manage_assets_screen.dart';
import 'package:personal_finance/net_worth_provider.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _MainNetWorthCard(),
          SizedBox(height: 24),
          _AssetsCard(),
          SizedBox(height: 24),
          _LiabilitiesCard(),
        ],
      ),
    );
  }
}

/// A large card displaying the main net worth figure.
class _MainNetWorthCard extends ConsumerWidget {
  const _MainNetWorthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthProvider);
    final changeAsync = ref.watch(netWorthChangeProvider);
    final currency = ref.watch(currencyProvider);

    return netWorthAsync.when(
        data: (netWorth) => Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text('Total Net Worth',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(AppFormatters.formatCurrency(netWorth, currency),
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)),
                    const SizedBox(height: 8),
                    changeAsync.when(
                      data: (change) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              change >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: change >= 0 ? Colors.green : Colors.red,
                              size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${change >= 0 ? '+' : ''}${AppFormatters.formatCurrency(change, currency)} this month',
                            style: TextStyle(
                                color: change >= 0 ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(),
                      error: (e, s) => const SizedBox(),
                    )
                  ],
                ),
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'));
  }
}

/// A card listing all asset accounts.
class _AssetsCard extends ConsumerWidget {
  const _AssetsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetListProvider);
    final totalAssetsAsync = ref.watch(totalAssetsProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assets', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManageAssetsScreen())),
                  child: const Text('Manage'),
                )
              ],
            ),
            const Divider(height: 24),
            assetsAsync.when(
              data: (assets) => Column(
                children: assets.isEmpty
                    ? [const Text('No assets added.')]
                    : assets
                        .map((asset) => ListTile(
                              title: Text(asset.name),
                              trailing: Text(AppFormatters.formatCurrency(
                                  asset.value, currency)),
                            ))
                        .toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
            const Divider(height: 24),
            totalAssetsAsync.when(
              data: (total) => ListTile(
                title: const Text('Total Assets',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(AppFormatters.formatCurrency(total, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              loading: () => const SizedBox(),
              error: (e, s) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card listing all liability accounts.
class _LiabilitiesCard extends ConsumerWidget {
  const _LiabilitiesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emisAsync = ref.watch(emiListProvider);
    final totalLiabilitiesAsync = ref.watch(totalLiabilitiesProvider);
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liabilities (Loans)',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            emisAsync.when(
              data: (emis) {
                final activeEmis =
                    emis.where((e) => e.tenureRemainingMonths > 0).toList();
                return Column(
                  children: activeEmis.isEmpty
                      ? [const Text('No active loans.')]
                      : activeEmis
                          .map((emi) => ListTile(
                                title: Text(emi.loanName),
                                trailing: Text(AppFormatters.formatCurrency(
                                    emi.monthlyEmiAmount *
                                        emi.tenureRemainingMonths,
                                    currency)),
                              ))
                          .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
            const Divider(height: 24),
            totalLiabilitiesAsync.when(
              data: (total) => ListTile(
                title: const Text('Total Liabilities',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(AppFormatters.formatCurrency(total, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              loading: () => const SizedBox(),
              error: (e, s) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}


