import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:personal_finance/app_navigation.dart';
import 'package:personal_finance/db_helper.dart';
import 'package:personal_finance/notification_helper.dart';
import 'package:personal_finance/profile_screen.dart';
import 'package:personal_finance/shared_preferences_provider.dart';
import 'package:personal_finance/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:personal_finance/background_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Register the background task
  await Workmanager().registerPeriodicTask(
    "1",
    simpleTaskKey,
    frequency: const Duration(days: 1),
  );

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize notification service
  await NotificationService().init();

  // Initialize timezone data
  await _initTimezone();
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final currency = prefs.getString('currency') ?? 'USD';
  final themeModeString = prefs.getString('themeMode');
  final userName = prefs.getString('userName') ?? 'User';
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
    return MaterialApp(
      title: 'Personal Finance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Or ThemeMode.light / ThemeMode.dark
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}
