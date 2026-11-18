import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
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
  // Default `true` so the picker is always available; users can opt
  // out to fall back to the public Downloads directory.
  static const String _useFilePickerForExportKey =
      'app_use_file_picker_for_export';
  // Replaces the older "export only" key; covers both exports and
  // downloads so the experience is consistent.
  static const String _useFilePickerForFileOperationsKey =
      'app_use_file_picker_for_file_operations';
  // Sub-folder used when the picker is off. Default is "1Panel-Client"
  // so files are easy to find across platforms.
  static const String _fileSaveSubDirectoryNameKey =
      'app_file_save_sub_directory_name';
  static const String defaultFileSaveSubDirectoryName = '1Panel-Client';

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

  Future<Locale?> loadLocale({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (refresh) await prefs.reload();
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

  Future<UIRenderMode> loadUIRenderMode({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (refresh) await prefs.reload();
    final value = prefs.getString(_uiRenderModeKey);

    final configuredMode = UIRenderMode.values.asNameMap()[value] ??
        UIRenderPolicy.defaultMode(
          appLockEnabled:
              prefs.getBool(AppLockSettingsStore.enabledPreferenceKey) ?? false,
        );
    return UIRenderPolicy.resolveSupportedMode(configuredMode);
  }

  Future<void> saveUIRenderMode(UIRenderMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedMode = UIRenderPolicy.resolveSupportedMode(mode);
    final saved = await prefs.setString(_uiRenderModeKey, resolvedMode.name);
    if (!saved) {
      throw StateError('Failed to save $_uiRenderModeKey');
    }
  }

  // Controls whether OHOS picker dialogs (DocumentViewPicker /
  // AudioViewPicker / PhotoAccessHelper) are shown for exports and
  // downloads. When false, files are written silently to the public
  // Downloads directory under Open1Panel/<category>/.
  //
  // The legacy key `app_use_file_picker_for_export` is consulted on
  // first read for migration. New code should use the
  // `*FilePickerForFileOperations` pair so both export and download
  // share the same toggle.
  @Deprecated('Use loadUseFilePickerForFileOperations / saveUseFilePickerForFileOperations')
  Future<bool> loadUseFilePickerForExport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFilePickerForExportKey) ?? true;
  }

  @Deprecated('Use loadUseFilePickerForFileOperations / saveUseFilePickerForFileOperations')
  Future<void> saveUseFilePickerForExport(bool usePicker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFilePickerForExportKey, usePicker);
  }

  // Unified toggle covering both exports and downloads. The legacy
  // "export only" key is migrated on first read so existing users
  // keep their setting. Defaults to `true` (picker shown).
  Future<bool> loadUseFilePickerForFileOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final direct = prefs.getBool(_useFilePickerForFileOperationsKey);
    if (direct != null) {
      return direct;
    }
    // Migrate from the old key. Reading it once is enough — future
    // calls will hit the new key (or default) directly.
    final legacy = prefs.getBool(_useFilePickerForExportKey);
    if (legacy != null) {
      await prefs.setBool(_useFilePickerForFileOperationsKey, legacy);
      await prefs.remove(_useFilePickerForExportKey);
      return legacy;
    }
    return true;
  }

  Future<void> saveUseFilePickerForFileOperations(bool usePicker) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFilePickerForFileOperationsKey, usePicker);
  }

  // Sub-folder used when the picker is off. Empty string is allowed
  // and means "no parent folder" — files land directly under
  // <downloads>/<category>/<file>.
  Future<String> loadFileSaveSubDirectoryName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fileSaveSubDirectoryNameKey) ??
        defaultFileSaveSubDirectoryName;
  }

  Future<void> saveFileSaveSubDirectoryName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fileSaveSubDirectoryNameKey, name);
  }
}
