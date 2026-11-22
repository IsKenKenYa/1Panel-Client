import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';

enum CacheStrategy {
  memoryOnly,
  diskOnly,
  hybrid,
}

class AppPreferencesService {
  static final _writes = Lock();
  static const String _themeModeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';
  static const String _cacheStrategyKey = 'cache_strategy';
  static const String _cacheMaxSizeKey = 'cache_max_size_mb';
  static const String _useDynamicColorKey = 'app_use_dynamic_color';
  static const String _seedColorKey = 'app_seed_color';
  static const String _uiRenderModeKey = 'app_ui_render_mode';
  static const String _useFilePickerForFileOperationsKey =
      'app_use_file_picker_for_file_operations';
  static const String _fileSaveSubDirectoryNameKey =
      'app_file_save_sub_directory_name';
  // 各服务器上次浏览的目录，按 serverId 存成 JSON 映射。
  static const String _fileLastPathKey = 'app_file_last_path_by_server';
  static const String defaultFileSaveSubDirectoryName = 'KenPanel';

  Future<void> _write(
    String key,
    Future<bool> Function(SharedPreferences) persist,
  ) =>
      _writes.synchronized(() async {
        final prefs = await SharedPreferences.getInstance();
        try {
          if (!await persist(prefs)) throw StateError('无法保存设置 $key');
        } catch (_) {
          // SharedPreferences 在平台确认写入之前会修改内存中的值。
          await prefs.reload();
          rethrow;
        }
      });

  Future<(ThemeMode, bool, Color?)> loadAppearance() =>
      _writes.synchronized(() => (
            loadThemeMode(),
            loadUseDynamicColor(),
            loadSeedColor(),
          ).wait);

  Future<(Locale?, CacheStrategy, int, UIRenderMode)> loadAppSettings() =>
      _writes.synchronized(() => (
            loadLocale(),
            loadCacheStrategy(),
            loadCacheMaxSizeMB(),
            loadUIRenderMode(),
          ).wait);

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

  Future<void> saveThemeMode(ThemeMode mode) => _write(
        _themeModeKey,
        (prefs) => prefs.setString(_themeModeKey, mode.name),
      );

  Future<Locale?> loadLocale({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (refresh) await prefs.reload();
    final value = prefs.getString(_localeKey);
    if (value == null || value.isEmpty || value == 'system') {
      return null;
    }

    return Locale(value);
  }

  Future<void> saveLocale(Locale? locale) => _write(
        _localeKey,
        (prefs) => prefs.setString(_localeKey, locale?.languageCode ?? 'system'),
      );

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

  Future<void> saveCacheStrategy(CacheStrategy strategy) => _write(
        _cacheStrategyKey,
        (prefs) => prefs.setString(_cacheStrategyKey, strategy.name),
      );

  Future<int> loadCacheMaxSizeMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheMaxSizeKey) ?? 100;
  }

  Future<void> saveCacheMaxSizeMB(int sizeMB) {
    if (sizeMB <= 0) throw ArgumentError.value(sizeMB, 'sizeMB');
    return _write(
      _cacheMaxSizeKey,
      (prefs) => prefs.setInt(_cacheMaxSizeKey, sizeMB),
    );
  }

  Future<bool> loadUseDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDynamicColorKey) ?? true;
  }

  Future<void> saveUseDynamicColor(bool useDynamicColor) => _write(
        _useDynamicColorKey,
        (prefs) => prefs.setBool(_useDynamicColorKey, useDynamicColor),
      );

  Future<Color?> loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_seedColorKey);
    return value != null ? Color(value) : null;
  }

  Future<void> saveSeedColor(Color color) => _write(
        _seedColorKey,
        (prefs) => prefs.setInt(_seedColorKey, color.toARGB32()),
      );

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

  Future<UIRenderMode> saveUIRenderMode(UIRenderMode mode) async {
    final resolvedMode = UIRenderPolicy.resolveSupportedMode(mode);
    await _write(
      _uiRenderModeKey,
      (prefs) => prefs.setString(_uiRenderModeKey, resolvedMode.name),
    );
    return resolvedMode;
  }

  Future<bool> loadUseFilePickerForFileOperations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFilePickerForFileOperationsKey) ?? true;
  }

  Future<void> saveUseFilePickerForFileOperations(bool usePicker) => _write(
        _useFilePickerForFileOperationsKey,
        (prefs) => prefs.setBool(_useFilePickerForFileOperationsKey, usePicker),
      );

  // Sub-folder used when the picker is off. Empty string is allowed
  // and means "no parent folder" — files land directly under
  // <downloads>/<category>/<file>.
  Future<String> loadFileSaveSubDirectoryName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fileSaveSubDirectoryNameKey) ??
        defaultFileSaveSubDirectoryName;
  }

  Future<void> saveFileSaveSubDirectoryName(String name) => _write(
        _fileSaveSubDirectoryNameKey,
        (prefs) => prefs.setString(_fileSaveSubDirectoryNameKey, name),
      );

  /// 读取各服务器上次浏览的目录映射。
  ///
  /// 内容损坏时返回空映射：目录记忆属于体验优化，退回根目录即可，
  /// 不应让整个文件页无法使用。
  Future<Map<String, String>> loadFileLastPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fileLastPathKey);
    if (raw == null || raw.isEmpty) return const <String, String>{};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const <String, String>{};
    }
    if (decoded is! Map) return const <String, String>{};
    return {
      for (final entry in decoded.entries)
        if (entry.value is String) entry.key as String: entry.value as String,
    };
  }

  Future<void> saveFileLastPaths(Map<String, String> paths) => _write(
        _fileLastPathKey,
        (prefs) => prefs.setString(_fileLastPathKey, jsonEncode(paths)),
      );
}
