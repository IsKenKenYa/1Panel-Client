import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

/// 液态玻璃壳层必须给页面 FAB 留出底栏让位，否则按钮被玻璃栏覆盖。
void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required bool glass,
    required Widget body,
  }) async {
    // 手机形态由平台与宽度共同决定，这里固定为 android 以走紧凑壳层分支。
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    UIRenderPolicy.setLiquidGlassEnabled(
      glass ? UIRenderMode.liquidGlass : UIRenderMode.md3,
    );
    addTearDown(() => UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.md3));
    SharedPreferences.setMockInitialValues({});
    final currentServer = CurrentServerController();
    final pinned = PinnedModulesController();
    await currentServer.load();
    await pinned.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => ServerProvider()),
          ChangeNotifierProvider<CurrentServerController>.value(
              value: currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(value: pinned),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppShellPage(body: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget fabHost() {
    return Scaffold(
      body: const SizedBox.expand(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'probe-fab',
        onPressed: () {},
        label: const Text('New'),
      ),
    );
  }

  testWidgets('glass shell 中页面 FAB 位于玻璃底栏上方', (tester) async {
    await pumpShell(tester, glass: true, body: fabHost());

    final fab = tester.getRect(find.byType(FloatingActionButton));
    final bar = tester.getRect(find.byType(AppBottomNavigationBar));
    debugDefaultTargetPlatformOverride = null;

    expect(fab.bottom, lessThanOrEqualTo(bar.top),
        reason: 'FAB 必须整体位于玻璃底栏之上，否则会被栏覆盖');
    expect(tester.takeException(), isNull);
  });

  testWidgets('非玻璃模式下 FAB 贴近屏幕底部', (tester) async {
    await pumpShell(tester, glass: false, body: fabHost());

    final fab = tester.getRect(find.byType(FloatingActionButton));
    debugDefaultTargetPlatformOverride = null;

    expect(fab.bottom, greaterThan(844 - 120),
        reason: '实色底栏模式由 Scaffold 自行让位，不应保留玻璃栏高度');
    expect(tester.takeException(), isNull);
  });
}
