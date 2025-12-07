import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/models/asset_model.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  final Asset? asset; // To edit existing asset
  const AddAssetScreen({super.key, this.asset});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valueController;
  late TextEditingController _nameController;
  late TextEditingController _appreciationController;
  String? _selectedIcon;

  bool get _isEditing => widget.asset != null;

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

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.asset?.value.toString(),
    );
    _nameController = TextEditingController(
      text: widget.asset?.name,
    );
    _appreciationController = TextEditingController(
      text: widget.asset?.yearlyAppreciation?.toString(),
    );
    if (_isEditing) {
      _selectedIcon = widget.asset!.icon;
    } else {
      _selectedIcon = 'account_balance'; // Default icon
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _nameController.dispose();
    _appreciationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final value = double.parse(_valueController.text);
      final name = _nameController.text;
      final appreciation = _appreciationController.text.isNotEmpty
          ? double.tryParse(_appreciationController.text)
          : null;

      final newAsset = Asset(
        id: widget.asset?.id,
        name: name.isNotEmpty ? name : 'Unnamed Asset',
        value: value,
        yearlyAppreciation: appreciation,
        icon: _selectedIcon,
      );

      if (_isEditing) {
        await ref.read(assetListProvider.notifier).updateAsset(newAsset);
      } else {
        await ref.read(assetListProvider.notifier).addAsset(newAsset);
      }

      ref.invalidate(assetListProvider);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);

    InputDecoration getModernInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Asset' : 'New Asset',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Hero Value Field ---
              Center(
                child: Column(
                  children: [
                    Text(
                      'Enter Asset Value',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '$currency ',
                          prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: theme.disabledColor.withOpacity(0.3),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 2. Details Card ---
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: getModernInputDecoration(
                          'Asset Name (e.g. Savings Account)',
                          Icons.label_rounded),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _appreciationController,
                      decoration: getModernInputDecoration(
                          'Yearly Growth % (Optional)',
                          Icons.trending_up_rounded),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. Icon Selector ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Icon',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        alignment: WrapAlignment.center,
                        children: _availableIcons.entries.map((entry) {
                          final isSelected = _selectedIcon == entry.key;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIcon = entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : theme.scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : theme.dividerColor,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: colorScheme.primary
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected
                                    ? Colors.white
                                    : theme.iconTheme.color,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 4. Submit Button ---
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitForm,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _isEditing
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing ? 'Update Asset' : 'Save Asset',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
