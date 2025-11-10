import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:personal_finance/views/app_navigation.dart';
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/helper/notification_helper.dart';
import 'package:personal_finance/views/profile_screen.dart';
import 'package:personal_finance/controllers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:personal_finance/helper/background_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Register the background task for EMI checks
  await Workmanager().registerPeriodicTask(
    "1",
    emiCheckTaskKey,
    frequency: const Duration(days: 1),
  );

  // Schedule backup task based on saved frequency
  final backupFrequency = prefs.getString('autoBackupFrequency') ?? 'Never';
  if (backupFrequency != 'Never') {
    Duration frequency;
    switch (backupFrequency) {
      case 'Daily':
        frequency = const Duration(days: 1);
        break;
      case 'Weekly':
        frequency = const Duration(days: 7);
        break;
      case 'Monthly':
        frequency = const Duration(days: 30);
        break;
      default:
        frequency = const Duration(days: 7); // Default to weekly
    }
    await Workmanager().registerPeriodicTask(
      "2",
      backupTaskKey,
      frequency: frequency,
    );
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize notification service
  await NotificationService().init();

  // Initialize timezone data
  await _initTimezone();
  WidgetsFlutterBinding.ensureInitialized();

  final currency = prefs.getString('currency') ?? 'USD';
  final themeModeString = prefs.getString('themeMode');
  final userName = prefs.getString('userName') ?? 'User';
  final accentColorValue = prefs.getInt('accentColor');

  ThemeMode themeMode;
  if (themeModeString == 'light') {
    themeMode = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    themeMode = ThemeMode.dark;
  } else {
    themeMode = ThemeMode.system;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currencyProvider.overrideWith((ref) => currency),
        themeProvider.overrideWith((ref) => themeMode),
        userNameProvider.overrideWith((ref) => userName),
        if (accentColorValue != null)
          accentColorProvider.overrideWith((ref) => Color(accentColorValue)),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  String timeZoneName;
  try {
    timeZoneName = (await FlutterTimezone.getLocalTimezone()) as String;
  } catch (e) {
    // Fallback or default timezone
    timeZoneName = 'America/Detroit';
  }
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp(
      title: 'Personal Finance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}
