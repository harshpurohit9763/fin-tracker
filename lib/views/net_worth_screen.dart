import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/views/manage_assets_screen.dart';
import 'package:personal_finance/controllers/net_worth_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/models/asset_model.dart'; // Import Asset model

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32), // Top spacing
            Text(
              'Net Worth',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            const _MainNetWorthCard(),
            const SizedBox(height: 24),
            const _AssetsCard(),
            const SizedBox(height: 24),
            const _LiabilitiesCard(),
          ],
        ),
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
      data: (netWorth) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text('Total Net Worth',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
            const SizedBox(height: 8),
            Text(AppFormatters.formatCurrency(netWorth, currency),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
            const SizedBox(height: 8),
            changeAsync.when(
              data: (change) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      change >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: change >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${change >= 0 ? '+' : ''}${AppFormatters.formatCurrency(change, currency)} this month',
                    style: TextStyle(
                        color: change >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
              loading: () => const SizedBox(),
              error: (e, s) => const SizedBox(),
            )
          ],
        ),
      ),
      loading: () => Container(
        height: 200,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Container(
        height: 200,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
            child: Text(
          'Error: $e',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        )),
      ),
    );
  }
}

// Helper function to get IconData from string
IconData _getIconData(String? iconName) {
  if (iconName == null) return Icons.category; // Default fallback icon

  // A simple mapping for common icons. This can be extended.
  switch (iconName) {
    case 'wallet':
      return Icons.wallet;
    case 'savings':
      return Icons.savings;
    case 'attach_money':
      return Icons.attach_money;
    case 'account_balance':
      return Icons.account_balance;
    case 'home_outlined': // For liabilities
      return Icons.home_outlined;
    default:
      return Icons.category; // Generic fallback
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

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageAssetsScreen())),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Manage'),
              )
            ],
          ),
          const SizedBox(height: 16),
          assetsAsync.when(
            data: (assets) => Column(
              children: assets.isEmpty
                  ? [
                      Text('No assets added.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ))
                    ]
                  : assets
                      .map((asset) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getIconData(asset.icon), // Use dynamic icon
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(asset.name,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            )),
                                  ],
                                ),
                                Text(AppFormatters.formatCurrency(
                                    asset.value, currency),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            )),
                              ],
                            ),
                          ))
                      .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
                child: Text('Error: $e',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ))),
          ),
          const SizedBox(height: 16),
          totalAssetsAsync.when(
            data: (total) => Column(
              children: [
                Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Assets',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                      Text(AppFormatters.formatCurrency(total, currency),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Liabilities (Loans)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
          const SizedBox(height: 16),
          emisAsync.when(
            data: (emis) {
              final activeEmis =
                  emis.where((e) => e.tenureRemainingMonths > 0).toList();
              return Column(
                children: activeEmis.isEmpty
                    ? [
                        Text('No active loans.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ))
                      ]
                    : activeEmis
                        .map((emi) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.home_outlined, // Using home icon for loans
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(emi.loanName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface,
                                              )),
                                    ],
                                  ),
                                  Text(
                                      AppFormatters.formatCurrency(
                                          emi.monthlyEmiAmount *
                                              emi.tenureRemainingMonths,
                                          currency),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              )),
                                ],
                              ),
                            ))
                        .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
                child: Text('Error: $e',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ))),
          ),
          const SizedBox(height: 16),
          totalLiabilitiesAsync.when(
            data: (total) => Column(
              children: [
                Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Liabilities',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                      Text(AppFormatters.formatCurrency(total, currency),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

