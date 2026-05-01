import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';

enum CacheStrategy {
  memoryOnly,
  diskOnly,
  hybrid,
}

class AppPreferencesService {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';
  static const String _cacheStrategyKey = 'cache_strategy';
  static const String _cacheMaxSizeKey = 'cache_max_size_mb';
  static const String _useDynamicColorKey = 'app_use_dynamic_color';
  static const String _seedColorKey = 'app_seed_color';
  static const String _uiRenderModeKey = 'app_ui_render_mode';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await prefs.setString(_themeModeKey, value);
  }

  Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_localeKey);
    if (value == null || value.isEmpty || value == 'system') {
      return null;
    }

    return Locale(value);
  }

  Future<void> saveLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_localeKey, 'system');
      return;
    }

    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<CacheStrategy> loadCacheStrategy() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_cacheStrategyKey);

    switch (value) {
      case 'memoryOnly':
        return CacheStrategy.memoryOnly;
      case 'diskOnly':
        return CacheStrategy.diskOnly;
      case 'hybrid':
        return CacheStrategy.hybrid;
      default:
        return CacheStrategy.hybrid;
    }
  }

  Future<void> saveCacheStrategy(CacheStrategy strategy) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (strategy) {
      CacheStrategy.memoryOnly => 'memoryOnly',
      CacheStrategy.diskOnly => 'diskOnly',
      CacheStrategy.hybrid => 'hybrid',
    };

    await prefs.setString(_cacheStrategyKey, value);
  }

  Future<int> loadCacheMaxSizeMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheMaxSizeKey) ?? 100;
  }

  Future<void> saveCacheMaxSizeMB(int sizeMB) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheMaxSizeKey, sizeMB);
  }

  Future<bool> loadUseDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDynamicColorKey) ?? true;
  }

  Future<void> saveUseDynamicColor(bool useDynamicColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, useDynamicColor);
  }

  Future<Color?> loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_seedColorKey);
    return value != null ? Color(value) : null;
  }

  Future<void> saveSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }

  Future<UIRenderMode> loadUIRenderMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_uiRenderModeKey);

    UIRenderMode configuredMode;
    switch (value) {
      case 'md3':
        configuredMode = UIRenderMode.md3;
        break;
      case 'native':
        configuredMode = UIRenderMode.native;
        break;
      default:
        configuredMode = UIRenderMode.md3;
        break;
    }

    return UIRenderPolicy.resolveSupportedMode(configuredMode);
  }

  Future<void> saveUIRenderMode(UIRenderMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedMode = UIRenderPolicy.resolveSupportedMode(mode);
    final value = switch (resolvedMode) {
      UIRenderMode.md3 => 'md3',
      UIRenderMode.native => 'native',
    };

    await prefs.setString(_uiRenderModeKey, value);
  }
}
