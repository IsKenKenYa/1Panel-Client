import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/services/app_preferences_service.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({AppPreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? AppPreferencesService();

  final AppPreferencesService _preferencesService;

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _seedColor = AppDesignTokens.brand;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get seedColor => _seedColor;
  bool get loaded => _loaded;

  Future<void> load() async {
    _themeMode = await _preferencesService.loadThemeMode();
    _useDynamicColor = await _preferencesService.loadUseDynamicColor();
    final loadedSeedColor = await _preferencesService.loadSeedColor();
    if (loadedSeedColor != null) {
      _seedColor = loadedSeedColor;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _preferencesService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> updateUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;
    _useDynamicColor = value;
    await _preferencesService.saveUseDynamicColor(value);
    notifyListeners();
  }

  Future<void> updateSeedColor(Color color) async {
    if (_seedColor == color) return;
    _seedColor = color;
    await _preferencesService.saveSeedColor(color);
    notifyListeners();
  }

  Future<void> resetSeedColor() async {
    await updateSeedColor(AppDesignTokens.brand);
  }
}
