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

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // M3 Expressive 信息密度：桌面鼠标精准定位走 compact，
      // 移动端保持 standard（触控目标高度由按钮 minSize 与 ListTile 下探共同保障）。
      visualDensity:
          isDesktop ? VisualDensity.compact : VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: isDesktop ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(
              color: isMacOS
                  ? scheme.outlineVariant.withValues(alpha: 0.5)
                  : scheme.outlineVariant),
        ),
        color: isMacOS ? scheme.surface.withValues(alpha: 0.8) : scheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: isDesktop ? 0 : 1,
        indicatorColor: scheme.primaryContainer,
        backgroundColor: scheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
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
      // M3 Expressive：按钮 full-round（pill）形状。
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 44),
          elevation: isDesktop ? 0 : null,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 44),
        ),
      ),
      // M3 Expressive：弹层统一大圆角（28dp）与低层级表面色。
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: isDesktop ? 0 : 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesignTokens.radiusXl),
          ),
        ),
        showDragHandle: true,
      ),
      // 桌面端滚动条常显（鼠标定位长列表），移动端保持系统默认行为。
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(isDesktop),
        thickness: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.dragged)
                  ? 8.0
                  : 6.0,
        ),
        radius: const Radius.circular(AppDesignTokens.radiusMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        ),
      ),
      // ── M3 Expressive 强化批：形状/层级/动效统一 ──
      // FAB：M3E 使用 rounded-square 大圆角（20dp），与 pill 按钮区分层级。
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        ),
        elevation: isDesktop ? 0 : 3,
      ),
      // SnackBar：浮动圆角 16 + inverse 表面（M3E 表达式反馈）。
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
      ),
      // TabBar：胶囊形主色指示器（M3E rounded indicator）。
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      // 菜单/弹出层统一 16dp 圆角。
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
              scheme.surfaceContainerLow),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
          ),
        ),
      ),
      // 列表项统一圆角按压反馈（M3E state layer 形状）+ 密度收紧：
      // 水平内边距 16→12、负向 visualDensity 下探行高（桌面 -4 / 移动 -2），
      // leading 图标降为次级色（M3 列表规范）。
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
        visualDensity:
            VisualDensity(horizontal: -2, vertical: isDesktop ? -4 : -2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingMd,
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
      // 进度指示统一圆头与主色。
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      // 分段按钮：M3E selected 层级增强。
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.selected)
                    ? scheme.primary
                    : scheme.outlineVariant,
              )),
        ),
      ),
      // 下拉菜单（DropdownButtonFormField 用）统一圆角。
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(scheme.surfaceContainerLow),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
