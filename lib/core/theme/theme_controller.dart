import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({AppPreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? AppPreferencesService();

  final AppPreferencesService _preferencesService;

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _seedColor = AppDesignTokens.brand;
  UIRenderMode _uiRenderMode = UIRenderMode.md3;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get seedColor => _seedColor;
  UIRenderMode get uiRenderMode => _uiRenderMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    _themeMode = await _preferencesService.loadThemeMode();
    _useDynamicColor = await _preferencesService.loadUseDynamicColor();
    _uiRenderMode = await _preferencesService.loadUIRenderMode();
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

  Future<void> updateUIRenderMode(UIRenderMode mode) async {
    if (_uiRenderMode == mode) return;
    _uiRenderMode = mode;
    await _preferencesService.saveUIRenderMode(mode);
    notifyListeners();
  }

  Future<void> resetSeedColor() async {
    await updateSeedColor(AppDesignTokens.brand);
  }
}
