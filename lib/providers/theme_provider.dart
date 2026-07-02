import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/app_settings.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    final modeStr = settings.themeMode;
    if (modeStr == 'light') {
      state = ThemeMode.light;
    } else if (modeStr == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    settings.themeMode = modeStr;
    await DatabaseService.settingsBox.put('settings', settings);
  }
}
