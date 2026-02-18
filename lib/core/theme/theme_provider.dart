import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Theme mode provider (persisted via Hive)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadFromStorage();
  }

  static const _boxKey = 'app_settings';
  static const _themeKey = 'theme_mode';

  Future<void> _loadFromStorage() async {
    try {
      final box = await Hive.openBox(_boxKey);
      final stored = box.get(_themeKey, defaultValue: 'dark') as String;
      state = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Hive might not be initialized yet — keep default (dark)
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    try {
      final box = await Hive.openBox(_boxKey);
      await box.put(_themeKey, state == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  bool get isDark => state == ThemeMode.dark;
}
