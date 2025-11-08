import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final currencyProvider = StateProvider<String>((ref) => 'USD');

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Provider for User Name
final userNameProvider = StateProvider<String>((ref) => 'User');

final accentColorProvider = StateProvider<Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final colorValue = prefs.getInt('accentColor') ?? Colors.deepPurple.value;
  return Color(colorValue);
});
