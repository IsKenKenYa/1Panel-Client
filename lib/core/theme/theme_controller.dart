import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class ThemeController extends ChangeNotifier with SafeChangeNotifier {
  ThemeController({AppPreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? AppPreferencesService();

  final AppPreferencesService _preferencesService;

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _seedColor = AppDesignTokens.seedColor;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get seedColor => _seedColor;
  bool get loaded => _loaded;

  Future<void> load() async {
    final (mode, dynamicColor, seedColor) =
        await _preferencesService.loadAppearance();
    _themeMode = mode;
    _useDynamicColor = dynamicColor;
    _seedColor = seedColor ?? AppDesignTokens.seedColor;
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _preferencesService.saveThemeMode(mode);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> updateUseDynamicColor(bool value) async {
    await _preferencesService.saveUseDynamicColor(value);
    _useDynamicColor = value;
    notifyListeners();
  }

  Future<void> updateSeedColor(Color color) async {
    await _preferencesService.saveSeedColor(color);
    _seedColor = color;
    notifyListeners();
  }

  Future<void> resetSeedColor() async {
    await updateSeedColor(AppDesignTokens.seedColor);
  }
}
