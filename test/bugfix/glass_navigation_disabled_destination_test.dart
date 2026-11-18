import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('窄屏玻璃底栏在 $brightness 下保持标签清晰', (tester) async {
      final previousGlassEnabled = UIRenderPolicy.liquidGlassEnabled;
      UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.liquidGlass);
      addTearDown(
          () => UIRenderPolicy.liquidGlassEnabled = previousGlassEnabled);
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CurrentServerController()),
            ChangeNotifierProvider(create: (_) => PinnedModulesController()),
            ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: brightness == Brightness.light
                ? AppTheme.getLightTheme()
                : AppTheme.getDarkTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const AppShellPage(initialIndex: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final glass = tester.widget<GlassContainer>(find.byType(GlassContainer));
      final settings = glass.settings!;
      expect(settings.bodyMode, GlassBodyMode.clear);
      expect(settings.glassColor.a, lessThan(1));
      expect(settings.blur, 0.6);
      expect(find.byTooltip('Container Management'), findsOneWidget);

      final selected = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Settings'),
        ),
      );
      final disabled =
          tester.renderObject<RenderParagraph>(find.text('Containers'));
      expect(selected.maxLines, 1);
      expect(disabled.maxLines, 1);
      expect(disabled.size.height, selected.size.height);
      for (final backdrop in [Colors.black, Colors.white]) {
        final background = Color.alphaBlend(settings.glassColor, backdrop);
        final selectedColor = selected.text.style!.color!;
        final disabledColor =
            Color.alphaBlend(disabled.text.style!.color!, background);
        expect(_contrastRatio(selectedColor, background),
            greaterThanOrEqualTo(4.5));
        expect(
            _contrastRatio(disabledColor, background), greaterThanOrEqualTo(3));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('玻璃底栏禁用不可用目的地，连接后保留选择与内容焦点', (tester) async {
    final previousGlassEnabled = UIRenderPolicy.liquidGlassEnabled;
    UIRenderPolicy.setLiquidGlassEnabled(UIRenderMode.liquidGlass);
    addTearDown(() => UIRenderPolicy.liquidGlassEnabled = previousGlassEnabled);
    final hasServer = ValueNotifier(false);
    addTearDown(hasServer.dispose);
    final contentFocus = FocusNode();
    addTearDown(contentFocus.dispose);
    final activations = <int>[];
    const systemInset = 32.0;
    tester.view.padding =
        FakeViewPadding(bottom: systemInset * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: hasServer,
          builder: (context, connected, child) => Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: 2,
              onTap: activations.add,
              items: [
                const AppNavigationBarItem(
                  icon: Icons.dns_outlined,
                  selectedIcon: Icons.dns,
                  label: 'Servers',
                ),
                AppNavigationBarItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Dashboard',
                  enabled: connected,
                ),
                const AppNavigationBarItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
          child: Center(
            child: TextButton(
              focusNode: contentFocus,
              onPressed: () => hasServer.value = true,
              child: const Text('Connect'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dashboard = find.bySemanticsLabel(RegExp(r'\bDashboard\b'));
    final dashboardSemantics =
        tester.getSemantics(dashboard).getSemanticsData();
    expect(dashboardSemantics.flagsCollection.isEnabled, Tristate.isFalse);
    expect(dashboardSemantics.hasAction(SemanticsAction.tap), isFalse);
    expect(dashboardSemantics.flagsCollection.isFocused, Tristate.none);
    expect(find.byType(GlassContainer), findsOneWidget);
    final materialBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(materialBar.selectedIndex, 2);
    final bar = find.byType(AppBottomNavigationBar);
    final barRect = tester.getRect(bar);
    expect(
      barRect.bottom - tester.getBottomRight(find.byType(GlassContainer)).dy,
      systemInset,
    );

    await tester.tapAt(tester.getCenter(find.text('Dashboard')));
    expect(activations, isEmpty);

    contentFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, [0, 2]);

    contentFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(contentFocus.hasPrimaryFocus, isTrue);
    final glassBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
    expect(glassBar.selectedIndex, 2);
    expect(tester.getRect(bar), barRect);
    final connectedDashboardSemantics =
        tester.getSemantics(dashboard).getSemanticsData();
    expect(connectedDashboardSemantics.hasAction(SemanticsAction.tap), isTrue);
  });
}

double _contrastRatio(Color first, Color second) {
  final luminances = [first.computeLuminance(), second.computeLuminance()]
    ..sort();
  return (luminances.last + 0.05) / (luminances.first + 0.05);
}
