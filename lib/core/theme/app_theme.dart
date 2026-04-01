import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  /// Backward-compatible helper used across the app.
  static ThemeData create(ColorScheme scheme) {
    return _buildTheme(scheme);
  }

  static ThemeData getLightTheme({
    ColorScheme? dynamicScheme,
    Color? seedColor,
  }) {
    final scheme = _resolveScheme(
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
      seedColor: seedColor,
    );

    return _buildTheme(scheme);
  }

  static ThemeData getDarkTheme({
    ColorScheme? dynamicScheme,
    Color? seedColor,
  }) {
    final scheme = _resolveScheme(
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
      seedColor: seedColor,
    );

    return _buildTheme(scheme);
  }

  static ColorScheme _resolveScheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    Color? seedColor,
  }) {
    if (dynamicScheme != null && _supportsMaterialYouPlatform) {
      return dynamicScheme;
    }

    return ColorScheme.fromSeed(
      seedColor: seedColor ?? AppDesignTokens.brand,
      brightness: brightness,
    );
  }

  static bool get _supportsMaterialYouPlatform {
    // Gate used by theme resolution to apply dynamic colors only on Android.
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
        
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: (isMacOS || isWindows) ? Colors.transparent : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: (isMacOS || isWindows) ? Colors.transparent : scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: isDesktop ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(color: isMacOS ? scheme.outlineVariant.withValues(alpha: 0.5) : scheme.outlineVariant),
        ),
        color: isMacOS ? scheme.surface.withValues(alpha: 0.8) : scheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: isDesktop ? 0 : 1,
        indicatorColor: scheme.primaryContainer,
        backgroundColor: (isMacOS || isWindows) ? Colors.transparent : scheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: (isMacOS || isWindows) ? Colors.transparent : scheme.surface,
        indicatorColor: scheme.primaryContainer,
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
          elevation: isDesktop ? 0 : null,
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
