import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppPreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? AppPreferencesService();

  final AppPreferencesService _preferencesService;

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  bool _loaded = false;
  CacheStrategy _cacheStrategy = CacheStrategy.hybrid;
  int _cacheMaxSizeMB = 100;
  UIRenderMode _uiRenderMode = UIRenderMode.native;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get loaded => _loaded;
  CacheStrategy get cacheStrategy => _cacheStrategy;
  int get cacheMaxSizeMB => _cacheMaxSizeMB;
  UIRenderMode get uiRenderMode => _uiRenderMode;

  Future<void> load() async {
    _themeMode = await _preferencesService.loadThemeMode();
    _locale = await _preferencesService.loadLocale();
    _cacheStrategy = await _preferencesService.loadCacheStrategy();
    _cacheMaxSizeMB = await _preferencesService.loadCacheMaxSizeMB();
    _uiRenderMode = await _preferencesService.loadUIRenderMode();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _preferencesService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> updateLocale(Locale? locale) async {
    _locale = locale;
    await _preferencesService.saveLocale(locale);
    notifyListeners();
  }

  Future<void> updateCacheStrategy(CacheStrategy strategy) async {
    _cacheStrategy = strategy;
    await _preferencesService.saveCacheStrategy(strategy);
    notifyListeners();
  }

  Future<void> updateCacheMaxSizeMB(int sizeMB) async {
    _cacheMaxSizeMB = sizeMB;
    await _preferencesService.saveCacheMaxSizeMB(sizeMB);
    notifyListeners();
  }

  Future<void> updateUIRenderMode(UIRenderMode mode) async {
    _uiRenderMode = mode;
    await _preferencesService.saveUIRenderMode(mode);
    notifyListeners();
  }
}
