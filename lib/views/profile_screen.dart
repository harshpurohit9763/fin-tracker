import 'package:flutter/cupertino.dart';
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
    final isAmoled = ref.watch(isAmoledProvider);
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR'];
    final themes = {
      ThemeMode.system: 'System Default',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
      'amoled': 'AMOLED',
    };
    final themeColors = {
      'Default': Colors.deepPurple,
      'Blue': Colors.blue,
      'Teal': Colors.teal,
      'Green': Colors.green,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Red': Colors.red,
      'Brown': Colors.brown,
      'Grey': Colors.grey,
      'Black': Colors.black,
    };
    final selectedColorName = themeColors.entries
        .firstWhere(
            (entry) =>
                entry.value.value == ref.watch(accentColorProvider).value,
            orElse: () => themeColors.entries.first)
        .key;

    String selectedThemeKey;
    if (isAmoled) {
      selectedThemeKey = 'amoled';
    } else {
      selectedThemeKey = themes.entries
          .firstWhere((element) => element.key == currentTheme,
              orElse: () => themes.entries.first)
          .key
          .toString();
    }

    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final lightShadow = Color.lerp(scaffoldBackgroundColor, Colors.white, 0.1)!;
    final darkShadow = Color.lerp(scaffoldBackgroundColor, Colors.black, 0.1)!;

    final neumorphicBoxDecoration = BoxDecoration(
      color: scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: darkShadow,
          blurRadius: 10,
          offset: const Offset(5, 5),
        ),
        BoxShadow(
          color: lightShadow,
          blurRadius: 10,
          offset: const Offset(-5, -5),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: CupertinoNavigationBarBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Profile & Settings'),
            pinned: true,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
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
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: neumorphicBoxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'User Profile',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Your Name',
                                filled: true,
                                fillColor: scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Appearance Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: neumorphicBoxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.palette_outlined,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Appearance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedThemeKey,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: themes.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key is String
                                            ? entry.key as String
                                            : (entry.key as ThemeMode)
                                                .toString(),
                                        child: Text(entry.value),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);
                                  if (value == 'amoled') {
                                    ref.read(themeProvider.notifier).state =
                                        ThemeMode.dark;
                                    ref.read(isAmoledProvider.notifier).state =
                                        true;
                                    prefs.setString('themeMode', 'dark');
                                    prefs.setBool('isAmoled', true);
                                  } else {
                                    final themeMode = themes.entries
                                        .firstWhere((element) =>
                                            element.key.toString() == value)
                                        .key as ThemeMode;
                                    ref.read(themeProvider.notifier).state =
                                        themeMode;
                                    ref.read(isAmoledProvider.notifier).state =
                                        false;
                                    prefs.setString('themeMode',
                                        themeMode.toString().split('.').last);
                                    prefs.setBool('isAmoled', false);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Theme Color Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: neumorphicBoxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.color_lens_outlined,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Theme Color',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedColorName,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: themeColors.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: entry.value,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(entry.key),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  final color = themeColors[value];
                                  if (color != null) {
                                    ref
                                        .read(accentColorProvider.notifier)
                                        .state = color;
                                    final prefs =
                                        ref.read(sharedPreferencesProvider);
                                    await prefs.setInt(
                                        'accentColor', color.value);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Localization Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: neumorphicBoxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.language_outlined,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Localization',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: currencies
                                  .map((currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ))
                                  .toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  ref.read(currencyProvider.notifier).state =
                                      value;
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);
                                  prefs.setString('currency', value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Data Management Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: neumorphicBoxDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storage_outlined,
                                    size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Data Management',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: ref.watch(autoBackupFrequencyProvider),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: ['Daily', 'Weekly', 'Monthly', 'Never']
                                  .map((frequency) => DropdownMenuItem(
                                        value: frequency,
                                        child: Text(frequency),
                                      ))
                                  .toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  ref
                                      .read(
                                          autoBackupFrequencyProvider.notifier)
                                      .state = value;
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);

                                  await prefs.setString(
                                      'autoBackupFrequency', value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.layers_outlined,
                                  size: 20, color: Colors.grey.shade700),
                              title: const Text('Manage Categories'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageCategoriesScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.upload_outlined,
                                  size: 20, color: Colors.grey.shade700),
                              title: const Text('Export Data'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final prefs =
                                    ref.read(sharedPreferencesProvider);
                                final database =
                                    await DatabaseHelper.instance.database;
                                final backupService =
                                    DataBackupService(prefs, database);
                                await backupService.exportData(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.download_outlined,
                                  size: 20, color: Colors.grey.shade700),
                              title: const Text('Import Data'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final prefs =
                                    ref.read(sharedPreferencesProvider);
                                final database =
                                    await DatabaseHelper.instance.database;
                                final backupService =
                                    DataBackupService(prefs, database);
                                await backupService.importData(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red.shade700),
                              title: const Text(
                                'Delete All Data',
                                style: TextStyle(color: Colors.red),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _deleteAllData(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
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
