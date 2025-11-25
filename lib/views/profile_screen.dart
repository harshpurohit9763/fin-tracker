import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/controllers/category_provider.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/helper/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/views/manage_categories_screen.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/helper/data_backup_service.dart'; // Added import
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/controllers/subscription_provider.dart'; // Added import
import 'package:personal_finance/helper/dummy_data_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isNameChanged = false;

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(userNameProvider);
    _nameController = TextEditingController(text: initialName);
    _nameController.addListener(() {
      final hasChanged = _nameController.text != initialName;
      if (hasChanged != _isNameChanged) {
        setState(() {
          _isNameChanged = hasChanged;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _showTutorial(); // Removed tutorial call
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(currencyProvider);
    final currentTheme = ref.watch(themeProvider);

    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR'];

    // This is a more complete ProfileScreen from a previous step.
    // I will add the buttons here.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          if (_isNameChanged)
            TextButton(
              onPressed: () {
                _updateUserName(_nameController.text);
                FocusScope.of(context).unfocus(); // Dismiss keyboard
              },
              child: const Text('SAVE'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'User Profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Currency',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: currencies.map((currency) {
                  return RadioListTile<String>(
                    title: Text(currency),
                    value: currency,
                    groupValue: selectedCurrency,
                    onChanged: (value) async {
                      if (value != null) {
                        ref.read(currencyProvider.notifier).state = value;
                        final prefs = ref.read(sharedPreferencesProvider);
                        prefs.setString('currency', value);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default'),
                    value: ThemeMode.system,
                    groupValue: currentTheme,
                    onChanged: (value) => _updateTheme(value, 'system'),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: currentTheme,
                    onChanged: (value) => _updateTheme(value, 'light'),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: currentTheme,
                    onChanged: (value) => _updateTheme(value, 'dark'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Theme Color',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _ColorPicker(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Auto Backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: ref.watch(autoBackupFrequencyProvider),
                decoration: const InputDecoration(
                  labelText: 'Backup Frequency',
                  border: InputBorder.none,
                ),
                items: ['Daily', 'Weekly', 'Monthly', 'Never']
                    .map((frequency) => DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null) {
                    ref.read(autoBackupFrequencyProvider.notifier).state =
                        value;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setString('autoBackupFrequency', value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Manage Categories'),
            leading: const Icon(Icons.category),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Export Data'),
            leading: const Icon(Icons.upload_file),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              final database = await DatabaseHelper.instance.database;
              final backupService = DataBackupService(prefs, database);
              await backupService.exportData(context);
            },
          ),
          ListTile(
            title: const Text('Import Data'),
            leading: const Icon(Icons.cloud_download_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              final database = await DatabaseHelper.instance.database;
              final backupService = DataBackupService(prefs, database);
              await backupService.importData(context);
            },
          ),
          ListTile(
            title: const Text('Populate Dummy Data'),
            leading: const Icon(Icons.data_usage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Populate Dummy Data?'),
                  content: const Text(
                      'This will add dummy data to your application. Existing data will not be cleared.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Populate'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(dummyDataServiceProvider).populateDummyData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dummy data populated!')),
                );
                // Invalidate providers to refresh UI
                ref.invalidate(currentMonthSpendingProvider);
                ref.invalidate(upcomingEmisThisWeekCountProvider);
                ref.invalidate(last6MonthsSpendingProvider);
                ref.invalidate(next3UpcomingEmisProvider);
                ref.invalidate(expenseListProvider);
                ref.invalidate(incomeListProvider);
                ref.invalidate(categoryListProvider);
                ref.invalidate(budgetListProvider);
                ref.invalidate(emiListProvider);
                ref.invalidate(subscriptionListProvider);
                ref.invalidate(assetListProvider);
              }
            },
          ),
          ListTile(
            title: const Text('Delete All Data'),
            leading: const Icon(Icons.delete_forever),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _deleteAllData(context),
          ),
        ],
      ),
    );
  }

  void _updateTheme(ThemeMode? value, String themeString) async {
    if (value != null) {
      ref.read(themeProvider.notifier).state = value;
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('themeMode', themeString);
    }
  }

  void _updateUserName(String name) {
    if (name.isNotEmpty) {
      ref.read(userNameProvider.notifier).state = name;
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('userName', name);
      setState(() {
        _isNameChanged = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated!')));
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
            'Are you sure you want to delete all your financial data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final database = await DatabaseHelper.instance.database;
      await database.delete(DatabaseHelper.expensesTable);
      await database.delete(DatabaseHelper.incomeTable);
      await database.delete(DatabaseHelper.categoriesTable);
      await database.delete(DatabaseHelper.budgetsTable);
      await database.delete(DatabaseHelper.emisTable);
      await database.delete(DatabaseHelper.subscriptionsTable);
      await database.delete(DatabaseHelper.assetsTable);
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.clear(); // Clear all shared preferences

      // Optionally, reset providers to their initial state
      ref.invalidate(currentMonthSpendingProvider);
      ref.invalidate(upcomingEmisThisWeekCountProvider);
      ref.invalidate(last6MonthsSpendingProvider);
      ref.invalidate(next3UpcomingEmisProvider);
      ref.invalidate(expenseListProvider);
      ref.invalidate(incomeListProvider);
      ref.invalidate(categoryListProvider);
      ref.invalidate(budgetListProvider);
      ref.invalidate(emiListProvider);
      ref.invalidate(subscriptionListProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(userNameProvider);
      ref.invalidate(currencyProvider);
      ref.invalidate(themeProvider);
      ref.invalidate(accentColorProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted!')),
      );
    }
  }
}

class _ColorPicker extends ConsumerWidget {
  final List<Color> _colorOptions = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(accentColorProvider);

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: _colorOptions.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () async {
            ref.read(accentColorProvider.notifier).state = color;
            final prefs = ref.read(sharedPreferencesProvider);
            await prefs.setInt('accentColor', color.value);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                width: isSelected ? 3.0 : 1.0,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
