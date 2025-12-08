import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/helper/app_formater.dart';
import 'package:personal_finance/models/asset_model.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/views/add_asset_screen.dart';

class ManageAssetsScreen extends ConsumerStatefulWidget {
  const ManageAssetsScreen({super.key});

  @override
  ConsumerState<ManageAssetsScreen> createState() => _ManageAssetsScreenState();
}

class _ManageAssetsScreenState extends ConsumerState<ManageAssetsScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedAssets = {};

  final Map<String, IconData> _availableIcons = {
    'account_balance': Icons.account_balance_rounded,
    'home': Icons.home_rounded,
    'directions_car': Icons.directions_car_rounded,
    'savings': Icons.savings_rounded,
    'store': Icons.store_rounded,
    'business': Icons.business_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'crypto': Icons.currency_bitcoin_rounded,
  };

  void _toggleSelection(int assetId) {
    setState(() {
      if (_selectedAssets.contains(assetId)) {
        _selectedAssets.remove(assetId);
        if (_selectedAssets.isEmpty) _isSelectionMode = false;
      } else {
        _selectedAssets.add(assetId);
      }
    });
  }

  void _enterSelectionMode(int assetId) {
    setState(() {
      _isSelectionMode = true;
      _selectedAssets.add(assetId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedAssets.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetListProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Modern App Bar ---
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 100.0,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                _isSelectionMode
                    ? '${_selectedAssets.length} Selected'
                    : 'My Assets',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            actions: _isSelectionMode
                ? [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () => _confirmDeleteMultiple(context, ref),
                      ),
                    ),
                  ]
                : [],
          ),

          // --- Asset List & Summary ---
          assetsAsync.when(
            data: (assets) {
              // Calculate Total Asset Value
              final totalValue =
                  assets.fold(0.0, (sum, item) => sum + item.value);

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ---------------------------------------------
                      // INDEX 0: Total Summary Card
                      // ---------------------------------------------
                      if (index == 0) {
                        return _buildTotalAssetsCard(
                            context, totalValue, currency, assets.length);
                      }

                      // ---------------------------------------------
                      // INDEX 1: Empty State (If no assets)
                      // ---------------------------------------------
                      if (assets.isEmpty) {
                        return Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: theme.disabledColor.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('No assets found',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: theme.disabledColor)),
                            ],
                          ),
                        );
                      }

                      // ---------------------------------------------
                      // INDEX > 0: Asset List Items
                      // ---------------------------------------------
                      final asset = assets[index - 1]; // Offset index
                      final isSelected = _selectedAssets.contains(asset.id!);

                      return _buildAssetCard(
                        context,
                        asset: asset,
                        currency: currency,
                        isSelected: isSelected,
                      );
                    },
                    // If empty, count is 2 (Card + EmptyMsg). If data, count is N + 1.
                    childCount: assets.isEmpty ? 2 : assets.length + 1,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // --- Gradient FAB ---
      floatingActionButton: _isSelectionMode
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                elevation: 0,
                backgroundColor: Colors.transparent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddAssetScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Asset',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }

  // --- NEW: Total Wealth Summary Card ---
  Widget _buildTotalAssetsCard(
      BuildContext context, double totalValue, String currency, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Total Wealth',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppFormatters.formatCurrency(totalValue, currency),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Across $count active assets',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // --- Premium Asset Card Widget ---
  Widget _buildAssetCard(BuildContext context,
      {required Asset asset,
      required String currency,
      required bool isSelected}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) _enterSelectionMode(asset.id!);
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(asset.id!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddAssetScreen(asset: asset)),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.2)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : (_availableIcons[asset.icon] ??
                          Icons.grid_view_rounded),
                  color: isSelected ? Colors.white : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (asset.yearlyAppreciation != null &&
                        asset.yearlyAppreciation! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${asset.yearlyAppreciation}% APY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(asset.value, currency),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              if (!isSelected && !_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.chevron_right_rounded,
                      color: theme.hintColor.withOpacity(0.3)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMultiple(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Assets?', textAlign: TextAlign.center),
        content: Text(
            'Are you sure you want to delete ${_selectedAssets.length} selected assets?',
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                ref
                    .read(assetListProvider.notifier)
                    .deleteMultipleAssets(_selectedAssets.toList());
                _exitSelectionMode();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
