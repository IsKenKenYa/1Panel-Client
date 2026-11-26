import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/features/settings/screens/theme_settings_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);

  test('外观主题采用系统提供的浅色和深色方案', () {
    final dark = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );
    // 表面层级由主题按 M3 容器角色统一决定，强调色沿用传入方案的取值。
    for (final (theme, scheme) in [
      (AppTheme.getLightTheme(dynamicScheme: scheme), scheme),
      (AppTheme.getDarkTheme(dynamicScheme: dark), dark),
    ]) {
      expect(theme.colorScheme.primary, scheme.primary);
      expect(theme.colorScheme.secondary, scheme.secondary);
      expect(theme.colorScheme.brightness, scheme.brightness);
    }
  });

  testWidgets('系统配色可用时显示开关，设备无配色时提供主题色选择', (tester) async {
    final controller = ThemeController();
    addTearDown(controller.dispose);
    Widget page(ColorScheme? palette) => ChangeNotifierProvider.value(
          value: controller,
          child: Provider<ColorScheme?>.value(
            value: palette,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ThemeSettingsPage(),
            ),
          ),
        );

    await tester.pumpWidget(page(scheme));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byTooltip('#2196F3'), findsNothing);
    await tester.pumpWidget(page(null));
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byTooltip('#2196F3'), findsOneWidget);
  });
}
