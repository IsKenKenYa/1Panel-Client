import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import '../services/app_preferences_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_design_tokens.dart';

class NativeChannelHarmonySettings {
  static Future<Map<String, Object>> getAppearance(dynamic arguments) async {
    final preferences = AppPreferencesService();
    final appearance = await preferences.loadAppearance();
    final palette = await DynamicColorPlugin.getCorePalette();
    final accent = await DynamicColorPlugin.getAccentColor();
    return {
      'themeMode': appearance.$1.name,
      'useDynamicColor': appearance.$2,
      'seedColor': (appearance.$3 ?? AppDesignTokens.seedColor).toARGB32(),
      'dynamicColorAvailable': palette != null || accent != null,
    };
  }

  static Future<void> updateAppearance(dynamic arguments) async {
    final values = Map<String, dynamic>.from(arguments as Map);
    final preferences = AppPreferencesService();
    if (values.containsKey('themeMode')) {
      await preferences.saveThemeMode(
        ThemeMode.values.byName(values['themeMode'] as String),
      );
    }
    if (values.containsKey('useDynamicColor')) {
      await preferences.saveUseDynamicColor(values['useDynamicColor'] as bool);
    }
    if (values.containsKey('seedColor')) {
      await preferences.saveSeedColor(Color(values['seedColor'] as int));
    }
  }

  static Future<void> resetOnboarding(dynamic arguments) =>
      OnboardingService().resetAll();
}
