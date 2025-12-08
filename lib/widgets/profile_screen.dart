import 'dart:convert';
import 'dart:math';
import 'dart:ui'; // For Glassmorphism

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/asset_provider.dart';
import 'package:personal_finance/controllers/budget_provider.dart';
import 'package:personal_finance/controllers/category_provider.dart';
import 'package:personal_finance/controllers/dashboard_provider.dart';
import 'package:personal_finance/controllers/emi_provider.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/controllers/goal_provider.dart';
import 'package:personal_finance/controllers/income_provider.dart';
import 'package:personal_finance/views/badge_provider.dart';
import 'package:personal_finance/views/manage_categories_screen.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:personal_finance/helper/data_backup_service.dart';
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/controllers/subscription_provider.dart';
import 'package:personal_finance/helper/dummy_data_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isNameChanged = false;
  bool _isEncryptedBackupEnabled = false;

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
    _isEncryptedBackupEnabled =
        ref.read(sharedPreferencesProvider).getBool('encryptedBackup') ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAmoled = ref.watch(isAmoledProvider); // Watch isAmoledProvider
    final isDark = theme.brightness == Brightness.dark;

    // Background color
    final bgColor = isAmoled
        ? Colors.black
        : (isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE));

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
          SliverAppBar(
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Profile & Settings',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            actions: [
              if (_isNameChanged)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: () {
                      _updateUserName(_nameController.text);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),

          // --- Body ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfileHeader(theme, isDark),
                  const SizedBox(height: 32),
                  _buildAppearanceSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildDataSecuritySection(theme, isDark),
                  const SizedBox(height: 40),
                  _buildDangerZone(theme, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Hero Profile Header ---
  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final name = ref.watch(userNameProvider);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Enter your name",
            suffixIcon: Icon(Icons.edit_outlined, size: 16),
            suffixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ),
      ],
    );
  }

  // --- 2. Appearance Section ---
  Widget _buildAppearanceSection(ThemeData theme, bool isDark) {
    final selectedCurrency = ref.watch(currencyProvider);
    final currentTheme = ref.watch(themeProvider);
    final isAmoled = ref.watch(isAmoledProvider);
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR'];

    // Determine selected theme key
    String selectedThemeKey = 'System Default'; // Default value
    if (isAmoled) {
      selectedThemeKey = 'AMOLED';
    } else {
      switch (currentTheme) {
        case ThemeMode.system:
          selectedThemeKey = 'System Default';
          break;
        case ThemeMode.light:
          selectedThemeKey = 'Light';
          break;
        case ThemeMode.dark:
          selectedThemeKey = 'Dark';
          break;
      }
    }

    return _buildSectionContainer(
      theme,
      isDark,
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        _buildDropdownRow(
          context,
          label: 'Theme',
          value: selectedThemeKey,
          items: ['System Default', 'Light', 'Dark', 'AMOLED'],
          onChanged: (val) {
            if (val == 'AMOLED') {
              ref.read(themeProvider.notifier).state = ThemeMode.dark;
              ref.read(isAmoledProvider.notifier).state = true;
              _saveThemePreference('dark', true); // AMOLED is a variant of dark
            } else {
              ThemeMode mode;
              String modeString;
              switch (val) {
                case 'Light':
                  mode = ThemeMode.light;
                  modeString = 'light';
                  break;
                case 'Dark':
                  mode = ThemeMode.dark;
                  modeString = 'dark';
                  break;
                default: // 'System Default'
                  mode = ThemeMode.system;
                  modeString = 'system';
                  break;
              }
              ref.read(isAmoledProvider.notifier).state = false;
              ref.read(themeProvider.notifier).state = mode;
              _saveThemePreference(modeString, false);
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownRow(
          context,
          label: 'Currency',
          value: selectedCurrency,
          items: currencies,
          onChanged: (val) {
            if (val != null) {
              ref.read(currencyProvider.notifier).state = val;
              ref.read(sharedPreferencesProvider).setString('currency', val);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text("Accent Color",
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildColorPicker(ref),
      ],
    );
  }

  // --- 3. Data & Security Section ---
  Widget _buildDataSecuritySection(ThemeData theme, bool isDark) {
    return _buildSectionContainer(
      theme,
      isDark,
      title: 'Data & Security',
      icon: Icons.security_outlined,
      children: [
        // Backup Frequency
        _buildDropdownRow(
          context,
          label: 'Auto Backup',
          value: ref.watch(autoBackupFrequencyProvider),
          items: ['Daily', 'Weekly', 'Monthly', 'Never'],
          onChanged: (val) {
            if (val != null) {
              ref.read(autoBackupFrequencyProvider.notifier).state = val;
              ref
                  .read(sharedPreferencesProvider)
                  .setString('autoBackupFrequency', val);
            }
          },
        ),
        const Divider(height: 32),

        // Encryption Switch
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Encrypted Backups',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            _isEncryptedBackupEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(fontSize: 12, color: theme.hintColor),
          ),
          value: _isEncryptedBackupEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (val) {
            if (val) {
              _showSetPasswordDialog();
            } else {
              _disableEncryption();
            }
          },
        ),

        if (_isEncryptedBackupEnabled)
          _buildActionTile(
            context,
            icon: Icons.password_rounded,
            title: 'Update Password',
            onTap: _showUpdatePasswordDialog,
          ),

        const Divider(height: 32),

        _buildActionTile(
          context,
          icon: Icons.category_rounded,
          title: 'Manage Categories',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManageCategoriesScreen())),
        ),
        _buildActionTile(
          context,
          icon: Icons.upload_file_rounded,
          title: 'Export Data',
          onTap: () async {
            final prefs = ref.read(sharedPreferencesProvider);
            final db = await DatabaseHelper.instance.database;
            await DataBackupService(prefs, db).exportData(context);
          },
        ),
        _buildActionTile(
          context,
          icon: Icons.download_rounded,
          title: 'Import Data',
          onTap: () async {
            final prefs = ref.read(sharedPreferencesProvider);
            final db = await DatabaseHelper.instance.database;
            await DataBackupService(prefs, db).importData(context);
          },
        ),
      ],
    );
  }

  // --- 4. Danger Zone ---
  Widget _buildDangerZone(ThemeData theme, bool isDark) {
    return _buildSectionContainer(
      theme,
      isDark,
      title: 'Advanced',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      children: [
        _buildActionTile(
          context,
          icon: Icons.note_add_rounded,
          title: 'Populate Dummy Data',
          onTap: () => _populateDummyData(),
        ),
        _buildActionTile(
          context,
          icon: Icons.delete_forever_rounded,
          title: 'Delete All Data',
          color: Colors.red,
          onTap: () => _deleteAllData(context),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionContainer(ThemeData theme, bool isDark,
      {required String title,
      required IconData icon,
      required List<Widget> children,
      Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20, color: iconColor ?? theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(WidgetRef ref) {
    final themeColors = {
      'Default': Colors.deepPurple,
      'Blue': Colors.blue,
      'Teal': Colors.teal,
      'Green': Colors.green,
      'Orange': Colors.orange,
      'Red': Colors.red,
      'Black': Colors.black,
    };

    final selectedColor = ref.watch(accentColorProvider);

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themeColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = themeColors.entries.elementAt(index);
          final isSelected = entry.value.value == selectedColor.value;

          return GestureDetector(
            onTap: () async {
              ref.read(accentColorProvider.notifier).state = entry.value;
              await ref
                  .read(sharedPreferencesProvider)
                  .setInt('accentColor', entry.value.value);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: entry.value.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).iconTheme.color)?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18, color: color ?? Theme.of(context).iconTheme.color),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  // --- Logic Methods (Preserved) ---

  void _saveThemePreference(String mode, bool amoled) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('themeMode', mode);
    prefs.setBool('isAmoled', amoled);
  }

  void _updateUserName(String name) {
    if (name.isNotEmpty) {
      ref.read(userNameProvider.notifier).state = name;
      ref.read(sharedPreferencesProvider).setString('userName', name);
      setState(() => _isNameChanged = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  void _disableEncryption() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('encryptedMasterKey');
    prefs.setBool('encryptedBackup', false);
    setState(() => _isEncryptedBackupEnabled = false);
  }

  Future<void> _populateDummyData() async {
    final confirm = await _showConfirmDialog('Populate Dummy Data?',
        'This will add sample data for demonstration. Continue?');
    if (confirm) {
      await ref.read(dummyDataServiceProvider).populateDummyData();
      _refreshAllProviders();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Dummy data added!')));
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirm = await _showConfirmDialog(
        'Delete All Data?', 'Are you sure? This cannot be undone.',
        isDestructive: true);

    if (confirm) {
      final db = await DatabaseHelper.instance.database;
      // Delete from all tables
      await db.delete(DatabaseHelper.expensesTable);
      await db.delete(DatabaseHelper.incomeTable);
      await db.delete(DatabaseHelper.categoriesTable);
      await db.delete(DatabaseHelper.budgetsTable);
      await db.delete(DatabaseHelper.emisTable);
      await db.delete(DatabaseHelper.subscriptionsTable);
      await db.delete(DatabaseHelper.assetsTable);
      await db.delete(DatabaseHelper.goalsTable);
      await db.delete(DatabaseHelper.badgesTable);

      // Clear Prefs but keep settings
      final prefs = ref.read(sharedPreferencesProvider);
      final backupEnc = prefs.getBool('encryptedBackup');
      final backupKey = prefs.getString('encryptedMasterKey');
      final backupFreq = prefs.getString('autoBackupFrequency');

      await prefs.clear();

      if (backupEnc != null) await prefs.setBool('encryptedBackup', backupEnc);
      if (backupKey != null)
        await prefs.setString('encryptedMasterKey', backupKey);
      if (backupFreq != null)
        await prefs.setString('autoBackupFrequency', backupFreq);

      _refreshAllProviders();

      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All data deleted!')));
    }
  }

  void _refreshAllProviders() {
    ref.invalidate(currentMonthSpendingProvider);
    ref.invalidate(upcomingEmisThisWeekCountProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(incomeListProvider);
    ref.invalidate(categoryListProvider);
    ref.invalidate(budgetListProvider);
    ref.invalidate(emiListProvider);
    ref.invalidate(subscriptionListProvider);
    ref.invalidate(assetListProvider);
    ref.invalidate(goalListProvider);
    ref.invalidate(badgeListProvider);
    ref.invalidate(userNameProvider);
    ref.invalidate(currencyProvider);
    ref.invalidate(themeProvider);
    ref.invalidate(accentColorProvider);
  }

  Future<bool> _showConfirmDialog(String title, String content,
      {bool isDestructive = false}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: isDark
                  ? const Color(0xFF1E1E1E).withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isDestructive ? 'Delete' : 'Confirm'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _showSetPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Set Backup Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(passwordController, 'Password'),
                  const SizedBox(height: 16),
                  _buildPasswordField(confirmController, 'Confirm Password'),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() &&
                      passwordController.text == confirmController.text) {
                    _enableEncryption(passwordController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Set'),
              )
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Update Backup Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(oldPasswordController, 'Old Password'),
                  const SizedBox(height: 16),
                  _buildPasswordField(newPasswordController, 'New Password'),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    confirmController,
                    'Confirm New Password',
                    validator: (v) {
                      if (v != newPasswordController.text) {
                        return "Passwords don't match";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => _handlePasswordUpdate(
                    formKey,
                    oldPasswordController.text,
                    newPasswordController.text,
                    context),
                child: const Text('Update'),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePasswordUpdate(
      GlobalKey<FormState> formKey,
      String oldPassword,
      String newPassword,
      BuildContext dialogContext) async {
    if (!formKey.currentState!.validate()) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final storedEncryptedKey = prefs.getString('encryptedMasterKey');

    if (storedEncryptedKey == null ||
        !storedEncryptedKey.startsWith('ENCRYPTED_V1:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No valid encryption key found.")),
      );
      return;
    }

    try {
      // 1. Decrypt the master key with the old password
      final ivBase64 = storedEncryptedKey.substring(
          'ENCRYPTED_V1:'.length, 'ENCRYPTED_V1:'.length + 24);
      final encryptedDataBase64 =
          storedEncryptedKey.substring('ENCRYPTED_V1:'.length + 24);

      final iv = encrypt.IV.fromBase64(ivBase64);
      final encryptedData = encrypt.Encrypted.fromBase64(encryptedDataBase64);

      final oldKey =
          encrypt.Key.fromUtf8(oldPassword.padRight(32).substring(0, 32));
      final decrypter = encrypt.Encrypter(encrypt.AES(oldKey));

      final masterKey = decrypter.decrypt(encryptedData, iv: iv);

      // 2. Re-encrypt with the new password
      final newKey =
          encrypt.Key.fromUtf8(newPassword.padRight(32).substring(0, 32));
      final encrypter = encrypt.Encrypter(encrypt.AES(newKey));
      final newIv = encrypt.IV.fromLength(16); // Use a new IV for security
      final newEncryptedMasterKey = encrypter.encrypt(masterKey, iv: newIv);

      // 3. Save the new encrypted key
      await prefs.setString('encryptedMasterKey',
          'ENCRYPTED_V1:${newIv.base64}${newEncryptedMasterKey.base64}');

      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect old password.')),
      );
    }
  }

  void _enableEncryption(String password) {
    // Logic preserved from original
    final prefs = ref.read(sharedPreferencesProvider);
    final random = Random.secure();
    final masterKeyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final masterKey = base64Url.encode(masterKeyBytes);
    final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv = encrypt.IV.fromLength(16);
    final encryptedMasterKey = encrypter.encrypt(masterKey, iv: iv);

    prefs.setString('encryptedMasterKey',
        'ENCRYPTED_V1:${iv.base64}${encryptedMasterKey.base64}');
    prefs.setBool('encryptedBackup', true);
    prefs.remove('backupPassword');

    setState(() => _isEncryptedBackupEnabled = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Encryption Enabled')));
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (validator != null) return validator(v);
        return null;
      },
    );
  }
}
