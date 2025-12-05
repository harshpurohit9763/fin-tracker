import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final currencyProvider = StateProvider<String>((ref) => 'USD');

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final isAmoledProvider = StateProvider<bool>((ref) => false);

// Provider for User Name
final userNameProvider = StateProvider<String>((ref) => 'User');

final accentColorProvider = StateProvider<Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final colorValue = prefs.getInt('accentColor') ?? Colors.deepPurple.value;
  return Color(colorValue);
});

final autoBackupFrequencyProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('autoBackupFrequency') ?? 'Never';
});

// Provider for managing tutorial visibility
class TutorialVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  final SharedPreferences _prefs;

  TutorialVisibilityNotifier(this._prefs) : super({});

  static const String _tutorialKeyPrefix = 'tutorial_seen_';

  Future<bool> isTutorialSeen(String screenId) async {
    return _prefs.getBool('$_tutorialKeyPrefix$screenId') ?? false;
  }

  Future<void> setTutorialSeen(String screenId) async {
    await _prefs.setBool('$_tutorialKeyPrefix$screenId', true);
  }
}

final tutorialVisibilityProvider =
    Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialVisibilityNotifier(prefs);
});
