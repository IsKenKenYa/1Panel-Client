import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app_design_tokens.dart';

/// 共享主题（M3 / M3 Expressive 轨道）。
///
/// 强调色跟随系统动态色或用户选色；表面层级固定走 M3 的中性容器角色，
/// 使页面为灰底、内容卡与浮层逐级抬升。客户端工具不设品牌色，
/// 默认种子取低彩度中性色。
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
    return _buildTheme(
      _resolveScheme(
        brightness: Brightness.light,
        dynamicScheme: dynamicScheme,
        seedColor: seedColor,
      ),
      visualDensity,
    );
  }

  static ThemeData getDarkTheme({
    ColorScheme? dynamicScheme,
    Color? seedColor,
    VisualDensity visualDensity = VisualDensity.standard,
  }) {
    return _buildTheme(
      _resolveScheme(
        brightness: Brightness.dark,
        dynamicScheme: dynamicScheme,
        seedColor: seedColor,
      ),
      visualDensity,
    );
  }

  /// 内容卡与分组卡片的底色。
  ///
  /// 浅色取最亮的容器层（tone 100），在灰色页面上读作白卡；
  /// 深色沿 M3 的抬升方向取 surfaceContainer（tone 12）。
  static Color cardSurface(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLowest;

  /// 顶栏、底栏、侧栏与抽屉的底色，与页面同级。
  static Color chromeSurface(ColorScheme scheme) => scheme.surface;

  /// 对话框、菜单与底部面板的底色，浮在内容之上。
  static Color floatSurface(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest;

  /// 输入框与进度轨道的填充底色。
  static Color fieldSurface(ColorScheme scheme) =>
      scheme.surfaceContainerHighest;

  static ColorScheme _resolveScheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    Color? seedColor,
  }) {
    // 系统动态色由用户选定，保留其彩度；回退到内置种子时用 neutral 变体，
    // 使强调色停留在近灰阶。两者都重新生成，旧版构造里 surfaceContainer*
    // 会全部回退到 surface，重生成后全套角色才可用。
    final source = dynamicScheme?.primary ?? seedColor;
    return ColorScheme.fromSeed(
      seedColor: source ?? AppDesignTokens.seedColor,
      brightness: dynamicScheme?.brightness ?? brightness,
      dynamicSchemeVariant: source == null
          ? DynamicSchemeVariant.neutral
          : DynamicSchemeVariant.tonalSpot,
    );
  }

  static ThemeData _buildTheme(ColorScheme incoming, VisualDensity density) {
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final compact = density == VisualDensity.compact;
    final buttonSize = Size(0, compact ? 44 : kMinInteractiveDimension);

    // 浅色页面取 surfaceContainer（tone 94），卡片与浮层抬到 tone 100；
    // 深色页面保持 surface（tone 6），容器沿 M3 原生方向变亮。
    final scheme = incoming.brightness == Brightness.dark
        ? incoming
        : incoming.copyWith(surface: incoming.surfaceContainer);
    final cardColor = cardSurface(scheme);
    final chromeColor = chromeSurface(scheme);
    final floatColor = floatSurface(scheme);
    final fieldColor = fieldSurface(scheme);

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
        backgroundColor: chromeColor,
        foregroundColor: scheme.onSurface,
      ),
      // M3E 卡片：内容卡走最亮容器层 + 低层级描边，与灰色页面区分层级。
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
        color: isMacOS ? cardColor.withValues(alpha: 0.9) : cardColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: isDesktop ? 0 : 1,
        indicatorColor: scheme.secondaryContainer,
        backgroundColor: chromeColor,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: chromeColor,
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldColor,
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
      // M3 Expressive：弹层统一大圆角（28dp）与浮层底色。
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: floatColor,
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
        backgroundColor: floatColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
        ),
      ),
      // M3E filter chip：完整胶囊外形，选中态填充次级容器色与配对前景色。
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.38);
            }
            return states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
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
      // TabBar：等宽胶囊指示器，选中态主色填充配 onPrimary 文案。
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
      popupMenuTheme: PopupMenuThemeData(
        color: floatColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(floatColor),
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
        linearTrackColor: fieldColor,
        circularTrackColor: fieldColor,
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
      // 下拉菜单（DropdownButtonFormField 用）统一圆角与浮层底色。
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(floatColor),
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
