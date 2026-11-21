import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData create(
    ColorScheme scheme, {
    VisualDensity visualDensity = VisualDensity.standard,
  }) {
    return _buildTheme(scheme, visualDensity);
  }

  static ThemeData getLightTheme({
    ColorScheme? dynamicScheme,
    Color? seedColor,
    VisualDensity visualDensity = VisualDensity.standard,
  }) {
    final scheme = _resolveScheme(
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
      seedColor: seedColor,
    );

    return _buildTheme(scheme, visualDensity);
  }

  static ThemeData getDarkTheme({
    ColorScheme? dynamicScheme,
    Color? seedColor,
    VisualDensity visualDensity = VisualDensity.standard,
  }) {
    final scheme = _resolveScheme(
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
      seedColor: seedColor,
    );

    return _buildTheme(scheme, visualDensity);
  }

  static ColorScheme _resolveScheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    Color? seedColor,
  }) {
    if (dynamicScheme != null) {
      return dynamicScheme;
    }

    return ColorScheme.fromSeed(
      seedColor: seedColor ?? AppDesignTokens.brand,
      brightness: brightness,
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme, VisualDensity density) {
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final compact = density == VisualDensity.compact;
    final buttonSize = Size(0, compact ? 44 : kMinInteractiveDimension);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: density,
      materialTapTargetSize:
          compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      // M3 Expressive：卡片走 surfaceContainerLow 底色 + 低层级描边，
      // 与页面 surface 形成一层可辨识的抬升，而不是靠阴影区分。
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          side: BorderSide(
            color: isMacOS
                ? scheme.outlineVariant.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        color: isMacOS
            ? scheme.surfaceContainerLow.withValues(alpha: 0.9)
            : scheme.surfaceContainerLow,
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
          minimumSize: buttonSize,
          elevation: isDesktop ? 0 : null,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: buttonSize,
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
      // M3E filter chip：完整胶囊外形，选中态填充主色。
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        labelStyle: TextStyle(
          fontSize: 13,
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.38);
            }
            return states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface;
          }),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
      // M3 Expressive：等宽胶囊指示器 + 选中态主色、未选中次级色。
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
          color: scheme.primary,
        ),
        indicatorAnimation: TabIndicatorAnimation.elastic,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius:
            BorderRadius.circular(AppDesignTokens.radiusSm),
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
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
        visualDensity: density,
        minVerticalPadding: AppDesignTokens.spacingSm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingSm,
          vertical: AppDesignTokens.spacingXs,
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
          shape: const WidgetStatePropertyAll(StadiumBorder()),
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
