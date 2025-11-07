import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/manage_categories_screen.dart';
import 'package:offline_expense_tracker/shared_preferences_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(userNameProvider));
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
                onFieldSubmitted: (value) {
                  _updateUserName(value);
                },
                onEditingComplete: () {
                  // This is called when the user is done editing.
                  _updateUserName(_nameController.text);
                },
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
    }
  }
}
