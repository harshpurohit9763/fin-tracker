// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:personal_finance/helper/app_formater.dart';
// import 'package:personal_finance/models/asset_model.dart';
// import 'package:personal_finance/controllers/asset_provider.dart';
// import 'package:personal_finance/controllers/shared_preferences_provider.dart';

// class ManageAssetsScreen extends ConsumerStatefulWidget {
//   const ManageAssetsScreen({super.key});

//   @override
//   ConsumerState<ManageAssetsScreen> createState() => _ManageAssetsScreenState();
// }

// class _ManageAssetsScreenState extends ConsumerState<ManageAssetsScreen> {
//   bool _isSelectionMode = false;
//   final Set<int> _selectedAssets = {};

//   // A map of available icons
//   final Map<String, IconData> _availableIcons = {
//     'account_balance': Icons.account_balance,
//     'home': Icons.home,
//     'directions_car': Icons.directions_car,
//     'savings': Icons.savings,
//     'store': Icons.store,
//     'business': Icons.business,
//   };

//   void _toggleSelection(int assetId) {
//     setState(() {
//       if (_selectedAssets.contains(assetId)) {
//         _selectedAssets.remove(assetId);
//         if (_selectedAssets.isEmpty) {
//           _isSelectionMode = false;
//         }
//       } else {
//         _selectedAssets.add(assetId);
//       }
//     });
//   }

//   void _enterSelectionMode(int assetId) {
//     setState(() {
//       _isSelectionMode = true;
//       _selectedAssets.add(assetId);
//     });
//   }

//   void _exitSelectionMode() {
//     setState(() {
//       _isSelectionMode = false;
//       _selectedAssets.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final assetsAsync = ref.watch(assetListProvider);
//     final currency = ref.watch(currencyProvider);

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             pinned: true, // Keep it pinned for the actions
//             leading: _isSelectionMode
//                 ? IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: _exitSelectionMode,
//                   )
//                 : null,
//             title: Text(_isSelectionMode
//                 ? '${_selectedAssets.length} selected'
//                 : 'Manage Assets'),
//             actions: _isSelectionMode
//                 ? [
//                     IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () => _confirmDeleteMultiple(context, ref),
//                     ),
//                   ]
//                 : [],
//           ),
//           assetsAsync.when(
//             data: (assets) {
//               if (assets.isEmpty) {
//                 return const SliverFillRemaining(
//                     child: Center(child: Text('No assets added yet.')));
//               }
//               return SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                     final asset = assets[index];
//                     final isSelected = _selectedAssets.contains(asset.id!);
//                     return ListTile(
//                       tileColor: isSelected
//                           ? Theme.of(context)
//                               .colorScheme
//                               .primary
//                               .withOpacity(0.2)
//                           : null,
//                       leading: CircleAvatar(
//                         child: Icon(
//                             _availableIcons[asset.icon] ?? Icons.question_mark),
//                       ),
//                       title: Text(asset.name),
//                       trailing: Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(AppFormatters.formatCurrency(
//                               asset.value, currency)),
//                           if (asset.yearlyAppreciation != null &&
//                               asset.yearlyAppreciation! > 0)
//                             Text('${asset.yearlyAppreciation}% p.a.',
//                                 style: const TextStyle(
//                                     color: Colors.green, fontSize: 12)),
//                         ],
//                       ),
//                       onTap: () {
//                         if (_isSelectionMode) {
//                           _toggleSelection(asset.id!);
//                         } else {
//                           _showAddEditAssetDialog(context, ref, asset: asset);
//                         }
//                       },
//                       onLongPress: () {
//                         if (!_isSelectionMode) {
//                           _enterSelectionMode(asset.id!);
//                         }
//                       },
//                     );
//                   },
//                   childCount: assets.length,
//                 ),
//               );
//             },
//             loading: () => const SliverFillRemaining(
//                 child: Center(child: CircularProgressIndicator())),
//             error: (err, stack) =>
//                 SliverFillRemaining(child: Center(child: Text('Error: $err'))),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddEditAssetDialog(context, ref),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   void _confirmDeleteMultiple(BuildContext context, WidgetRef ref) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: Text('Delete ${_selectedAssets.length} Assets?'),
//         content: const Text(
//             'Are you sure you want to delete the selected assets? This action cannot be undone.'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('Cancel')),
//           TextButton(
//               onPressed: () {
//                 ref
//                     .read(assetListProvider.notifier)
//                     .deleteMultipleAssets(_selectedAssets.toList());
//                 _exitSelectionMode();
//                 Navigator.of(dialogContext).pop();
//               },
//               child: const Text('Delete', style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );
//   }

//   void _showAddEditAssetDialog(BuildContext context, WidgetRef ref,
//       {Asset? asset}) {
//     final isEditing = asset != null;
//     final formKey = GlobalKey<FormState>();
//     final nameController = TextEditingController(text: asset?.name);
//     final valueController =
//         TextEditingController(text: asset?.value.toString());
//     final appreciationController =
//         TextEditingController(text: asset?.yearlyAppreciation?.toString());
//     String? selectedIcon = asset?.icon;

//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: Text(isEditing ? 'Edit Asset' : 'Add Asset'),
//         content: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return Form(
//               key: formKey,
//               child: SingleChildScrollView(
//                 child: Column(mainAxisSize: MainAxisSize.min, children: [
//                   const Text('Select Icon'),
//                   Wrap(
//                     spacing: 8.0,
//                     children: _availableIcons.entries.map((entry) {
//                       return ChoiceChip(
//                         label: Icon(entry.value),
//                         selected: selectedIcon == entry.key,
//                         onSelected: (isSelected) {
//                           setState(() {
//                             selectedIcon = isSelected ? entry.key : null;
//                           });
//                         },
//                       );
//                     }).toList(),
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: nameController,
//                     decoration: const InputDecoration(
//                         labelText: 'Asset Name (e.g., Savings Account)'),
//                     validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
//                   ),
//                   TextFormField(
//                     controller: valueController,
//                     decoration:
//                         const InputDecoration(labelText: 'Current Value'),
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(
//                           RegExp(r'^\d*\.?\d{0,2}'))
//                     ],
//                     validator: (v) =>
//                         v!.isEmpty ? 'Please enter a value' : null,
//                   ),
//                   TextFormField(
//                     controller: appreciationController,
//                     decoration: const InputDecoration(
//                         labelText: 'Yearly Appreciation % (Optional)'),
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(
//                           RegExp(r'^\d*\.?\d{0,2}'))
//                     ],
//                   ),
//                 ]),
//               ),
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               if (formKey.currentState!.validate()) {
//                 final assetToSave = Asset(
//                     id: asset?.id,
//                     name: nameController.text,
//                     value: double.parse(valueController.text),
//                     yearlyAppreciation: appreciationController.text.isNotEmpty
//                         ? double.parse(appreciationController.text)
//                         : null,
//                     icon: selectedIcon);

//                 if (isEditing) {
//                   ref.read(assetListProvider.notifier).updateAsset(assetToSave);
//                 } else {
//                   ref.read(assetListProvider.notifier).addAsset(assetToSave);
//                 }

//                 Navigator.of(dialogContext).pop();
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                _isSelectionMode
                    ? '${_selectedAssets.length} Selected'
                    : 'My Assets',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 20, // Adjusted for sliver scaling
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

          // --- Asset List ---
          assetsAsync.when(
            data: (assets) {
              if (assets.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = assets[index];
                      final isSelected = _selectedAssets.contains(asset.id!);

                      return _buildAssetCard(
                        context,
                        asset: asset,
                        currency: currency,
                        isSelected: isSelected,
                      );
                    },
                    childCount: assets.length,
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
