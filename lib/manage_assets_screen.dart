import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/app_formater.dart';
import 'package:personal_finance/asset_model.dart';
import 'package:personal_finance/asset_provider.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

class ManageAssetsScreen extends ConsumerStatefulWidget {
  const ManageAssetsScreen({super.key});

  @override
  ConsumerState<ManageAssetsScreen> createState() => _ManageAssetsScreenState();
}

class _ManageAssetsScreenState extends ConsumerState<ManageAssetsScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedAssets = {};

  // A map of available icons
  final Map<String, IconData> _availableIcons = {
    'account_balance': Icons.account_balance,
    'home': Icons.home,
    'directions_car': Icons.directions_car,
    'savings': Icons.savings,
    'store': Icons.store,
    'business': Icons.business,
  };

  void _toggleSelection(int assetId) {
    setState(() {
      if (_selectedAssets.contains(assetId)) {
        _selectedAssets.remove(assetId);
        if (_selectedAssets.isEmpty) {
          _isSelectionMode = false;
        }
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

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(_isSelectionMode
            ? '${_selectedAssets.length} selected'
            : 'Manage Assets'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteMultiple(context, ref),
                ),
              ]
            : [],
      ),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const Center(child: Text('No assets added yet.'));
          }
          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              final isSelected = _selectedAssets.contains(asset.id!);
              return ListTile(
                tileColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : null,
                leading: CircleAvatar(
                  child:
                      Icon(_availableIcons[asset.icon] ?? Icons.question_mark),
                ),
                title: Text(asset.name),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppFormatters.formatCurrency(asset.value, currency)),
                    if (asset.yearlyAppreciation != null &&
                        asset.yearlyAppreciation! > 0)
                      Text('${asset.yearlyAppreciation}% p.a.',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12)),
                  ],
                ),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(asset.id!);
                  } else {
                    _showAddEditAssetDialog(context, ref, asset: asset);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(asset.id!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAssetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteMultiple(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${_selectedAssets.length} Assets?'),
        content: const Text(
            'Are you sure you want to delete the selected assets? This action cannot be undone.'),
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

  void _showAddEditAssetDialog(BuildContext context, WidgetRef ref,
      {Asset? asset}) {
    final isEditing = asset != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: asset?.name);
    final valueController =
        TextEditingController(text: asset?.value.toString());
    final appreciationController =
        TextEditingController(text: asset?.yearlyAppreciation?.toString());
    String? selectedIcon = asset?.icon;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Edit Asset' : 'Add Asset'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Select Icon'),
                  Wrap(
                    spacing: 8.0,
                    children: _availableIcons.entries.map((entry) {
                      return ChoiceChip(
                        label: Icon(entry.value),
                        selected: selectedIcon == entry.key,
                        onSelected: (isSelected) {
                          setState(() {
                            selectedIcon = isSelected ? entry.key : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Asset Name (e.g., Savings Account)'),
                    validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                  ),
                  TextFormField(
                    controller: valueController,
                    decoration:
                        const InputDecoration(labelText: 'Current Value'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a value' : null,
                  ),
                  TextFormField(
                    controller: appreciationController,
                    decoration: const InputDecoration(
                        labelText: 'Yearly Appreciation % (Optional)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final assetToSave = Asset(
                    id: asset?.id,
                    name: nameController.text,
                    value: double.parse(valueController.text),
                    yearlyAppreciation: appreciationController.text.isNotEmpty
                        ? double.parse(appreciationController.text)
                        : null,
                    icon: selectedIcon);

                if (isEditing) {
                  ref.read(assetListProvider.notifier).updateAsset(assetToSave);
                } else {
                  ref.read(assetListProvider.notifier).addAsset(assetToSave);
                }

                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
