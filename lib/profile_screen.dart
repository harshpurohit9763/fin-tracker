import 'package:personal_finance/emi_provider.dart';
import 'package:personal_finance/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/manage_categories_screen.dart';
import 'package:personal_finance/shared_preferences_provider.dart';

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
          // ListTile(
          //   title: const Text('Send Test EMI Notification'),
          //   leading: const Icon(Icons.notification_add),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () {
          //     final emisAsyncValue = ref.read(emiListProvider);
          //     emisAsyncValue.when(
          //       data: (emis) {
          //         if (emis.isNotEmpty) {
          //           final upcomingEmis = emis
          //               .where((emi) => emi.nextDueDate.isAfter(DateTime.now()))
          //               .toList();
          //           if (upcomingEmis.isNotEmpty) {
          //             upcomingEmis.sort((a, b) =>
          //                 a.nextDueDate.compareTo(b.nextDueDate));
          //             final nextEmi = upcomingEmis.first;
          //             final daysLeft =
          //                 nextEmi.nextDueDate.difference(DateTime.now()).inDays;
          //             NotificationService().showEmiReminder(
          //               id: nextEmi.id!,
          //               loanName: nextEmi.loanName,
          //               amount: nextEmi.monthlyEmiAmount,
          //               daysLeft: daysLeft,
          //             );
          //           } else {
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               const SnackBar(
          //                 content: Text(
          //                     'No upcoming EMIs to send a notification for.'),
          //               ),
          //             );
          //           }
          //         } else {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content:
          //                   Text('No EMIs to send a notification for.'),
          //             ),
          //           );
          //         }
          //       },
          //       loading: () =>
          //           ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('Loading EMIs...'),
          //         ),
          //       ),
          //       error: (error, stackTrace) =>
          //           ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text('Error loading EMIs: $error'),
          //         ),
          //       ),
          //     );
          //   },
          // ),
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
