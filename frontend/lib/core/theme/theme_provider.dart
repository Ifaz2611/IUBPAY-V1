import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

const _kThemeKey = 'iub_theme_mode';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load persisted preference asynchronously and update state when ready
    Future.microtask(_load);
    return ThemeMode.light;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kThemeKey);
      if (raw == 'dark') { state = ThemeMode.dark; AppThemeState.setDark(true); }
      else if (raw == 'light') { state = ThemeMode.light; AppThemeState.setDark(false); }
      else if (raw == 'system') state = ThemeMode.system;
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    AppThemeState.setDark(mode == ThemeMode.dark);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_kThemeKey, raw);
    } catch (_) {}
  }

  Future<void> toggle() async {
    // ensure AppThemeState updated via setTheme
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    // Simple light <-> dark toggle; system resolves to opposite of current effective
    await setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool isDark(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
