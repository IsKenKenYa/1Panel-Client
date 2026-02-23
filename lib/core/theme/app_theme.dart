import 'package:flutter/material.dart';
import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData getLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppDesignTokens.brand,
      brightness: Brightness.light,
    );

    return _buildTheme(scheme);
  }

  static ThemeData getDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppDesignTokens.brand,
      brightness: Brightness.dark,
    );

    return _buildTheme(scheme);
  }

  static ThemeData create(ColorScheme scheme) {
    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        indicatorColor: scheme.primaryContainer,
        backgroundColor: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        ),
      ),
    );
  }
}
