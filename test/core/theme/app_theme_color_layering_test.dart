import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';

/// 亮度排序：0 最暗，1 最亮，用于断言角色之间的抬升方向。
double _luminance(Color color) => color.computeLuminance();

void main() {
  group('浅色表面层级', () {
    final theme = AppTheme.getLightTheme();

    test('页面为中性灰，内容卡比页面更亮', () {
      final scheme = theme.colorScheme;
      expect(theme.scaffoldBackgroundColor, scheme.surface);
      expect(
        _luminance(scheme.surface),
        lessThan(_luminance(AppTheme.cardSurface(scheme))),
        reason: '页面必须比内容卡深，否则整屏读作一片白',
      );
      expect(
        _luminance(scheme.surface),
        lessThan(0.92),
        reason: '浅色页面底色需达到可见的灰底层级',
      );
    });

    test('浮层与内容卡同为最亮层，高于页面与输入框', () {
      final scheme = theme.colorScheme;
      expect(
        _luminance(AppTheme.floatSurface(scheme)),
        greaterThan(_luminance(scheme.surface)),
      );
      expect(
        _luminance(AppTheme.fieldSurface(scheme)),
        lessThanOrEqualTo(_luminance(scheme.surface)),
        reason: '输入框填充需落在页面或更深处才可辨识',
      );
    });

    test('壳层铬件底色与页面同级，卡片与之拉开', () {
      final scheme = theme.colorScheme;
      expect(AppTheme.chromeSurface(scheme), scheme.surface);
      expect(theme.appBarTheme.backgroundColor, scheme.surface);
      expect(theme.navigationBarTheme.backgroundColor, scheme.surface);
      expect(theme.navigationRailTheme.backgroundColor, scheme.surface);
    });
  });

  group('深色表面层级', () {
    final theme = AppTheme.getDarkTheme();

    test('页面保持 M3 原生深色，容器沿抬升方向变亮', () {
      final scheme = theme.colorScheme;
      expect(theme.scaffoldBackgroundColor, scheme.surface);
      expect(
        _luminance(AppTheme.cardSurface(scheme)),
        greaterThan(_luminance(scheme.surface)),
      );
      expect(
        _luminance(AppTheme.floatSurface(scheme)),
        greaterThan(_luminance(AppTheme.cardSurface(scheme))),
      );
    });
  });

  group('强调色与选中态', () {
    test('默认主题使用中性种子，强调色低彩度', () {
      for (final theme in [AppTheme.getLightTheme(), AppTheme.getDarkTheme()]) {
        final scheme = theme.colorScheme;
        expect(scheme.primary, isNot(equals(Colors.transparent)));
        final hsv = HSVColor.fromColor(scheme.primary);
        expect(
          hsv.saturation,
          lessThan(0.35),
          reason: '客户端工具不设品牌色，默认强调色应保持低彩度',
        );
      }
    });

    test('导航、标签与筛选的选中态使用容器角色配配对前景色', () {
      for (final theme in [AppTheme.getLightTheme(), AppTheme.getDarkTheme()]) {
        final scheme = theme.colorScheme;
        expect(theme.navigationBarTheme.indicatorColor,
            scheme.secondaryContainer);
        expect(theme.navigationRailTheme.indicatorColor,
            scheme.secondaryContainer);
        expect(theme.tabBarTheme.indicator, isA<BoxDecoration>());
        expect(
          ((theme.tabBarTheme.indicator) as BoxDecoration).color,
          scheme.primary,
        );
        expect(theme.tabBarTheme.labelColor, scheme.onPrimary);
        expect(theme.chipTheme.selectedColor, scheme.secondaryContainer);
        expect(theme.chipTheme.checkmarkColor, scheme.onSecondaryContainer);
      }
    });
  });

  group('动态色输入', () {
    test('动态色只贡献强调色，表面层级仍按 M3 容器角色生成', () {
      // dynamic_color 的旧版构造只填 45 个角色，surfaceContainer* 会回退
      // 到 surface；主题必须重新生成，保证层级关系不塌陷。
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6C4A),
        brightness: Brightness.light,
      );
      final theme = AppTheme.getLightTheme(dynamicScheme: dynamicScheme);
      final scheme = theme.colorScheme;
      expect(
        _luminance(scheme.surface),
        lessThan(_luminance(AppTheme.cardSurface(scheme))),
        reason: '动态色不得让页面与卡片同色',
      );
      expect(theme.chipTheme.selectedColor, scheme.secondaryContainer);
    });

    test('用户选色只改变强调色，页面灰底层级不变', () {
      final themed = AppTheme.getLightTheme(seedColor: Colors.deepOrange);
      final baseline = AppTheme.getLightTheme();
      expect(themed.colorScheme.primary,
          isNot(equals(baseline.colorScheme.primary)));
      expect(themed.colorScheme.surface.computeLuminance(),
          closeTo(baseline.colorScheme.surface.computeLuminance(), 0.1),
          reason: '页面层级由中性容器角色决定，不随强调色大幅偏移');
    });
  });

  test('默认种子色为中性灰而非品牌绿', () {
    final hsv = HSVColor.fromColor(AppDesignTokens.seedColor);
    expect(hsv.saturation, lessThan(0.2));
  });
}
