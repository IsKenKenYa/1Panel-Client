import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    AppShellPage home = const AppShellPage(),
    EdgeInsets? windowPadding,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final currentServer = CurrentServerController();
    final pinned = PinnedModulesController();
    await currentServer.load();
    await pinned.load();

    tester.view.physicalSize = size;
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
          builder: windowPadding == null
              ? null
              : (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: windowPadding,
                      viewPadding: windowPadding,
                    ),
                    child: child!,
                  ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders 4-slot primary navigation on compact width',
      (tester) async {
    await pumpShell(tester, size: const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    expect(find.descendant(of: navBar, matching: find.text('Servers')),
        findsWidgets);
    expect(find.descendant(of: navBar, matching: find.text('Files')),
        findsWidgets);
    expect(
        find.descendant(
            of: navBar, matching: find.text('Container Management')),
        findsWidgets);
    expect(find.descendant(of: navBar, matching: find.text('Settings')),
        findsWidgets);
  });

  testWidgets('opens left more-modules drawer on compact width',
      (tester) async {
    await pumpShell(tester, size: const Size(390, 844));

    final menuButton = find.byKey(const Key('shell-drawer-menu-button'));
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('More'), findsWidgets);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('glass shell uses the measured bottom bar as content padding',
      (tester) async {
    const size = Size(390, 844);
    const insets = EdgeInsets.fromLTRB(34, 24, 18, 28);
    const contentKey = ValueKey('glass-shell-content');
    final previousGlassEnabled = UIRenderPolicy.liquidGlassEnabled;
    UIRenderPolicy.liquidGlassEnabled = true;
    addTearDown(() {
      UIRenderPolicy.liquidGlassEnabled = previousGlassEnabled;
    });

    await pumpShell(
      tester,
      size: size,
      windowPadding: insets,
      home: const AppShellPage(body: SizedBox.expand(key: contentKey)),
    );

    final content = find.byKey(contentKey);
    final contentBounds = tester.getRect(content);
    final contentMetrics = MediaQuery.of(tester.element(content));
    final bottomBar = tester.getRect(find.byType(AppBottomNavigationBar));
    final barContent = tester.getRect(find.byType(NavigationBar));
    expect(contentBounds.left, insets.left);
    expect(contentBounds.right, size.width - insets.right);
    expect(contentBounds.bottom, size.height);
    expect(bottomBar.bottom, size.height);
    expect(barContent.bottom, size.height - insets.bottom);
    expect(contentMetrics.padding.bottom, bottomBar.height);
    // viewPadding 与 padding 同为栏高：FAB 的 safeMargin 用
    // minViewPadding.bottom - contentBottom + 16，两者一致才得 16dp 间距。
    expect(contentMetrics.viewPadding.bottom, bottomBar.height);
  });

  testWidgets('renders navigation rail on medium width', (tester) async {
    await pumpShell(tester, size: const Size(800, 1024));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final rail = find.byType(NavigationRail);
    expect(find.descendant(of: rail, matching: find.text('App Management')),
        findsWidgets);
    expect(find.descendant(of: rail, matching: find.text('Websites')),
        findsWidgets);
    expect(find.descendant(of: rail, matching: find.text('Security')),
        findsWidgets);
  });

  for (final (size, tabletKind) in const [
    (Size(390, 844), TabletKind.none),
    (Size(860, 600), TabletKind.harmonyPad),
  ]) {
    testWidgets('applies window insets once for ${tabletKind.name}',
        (tester) async {
      const insets = EdgeInsets.fromLTRB(34, 24, 18, 28);
      const contentKey = ValueKey('shell-content');
      final previousGlassEnabled = UIRenderPolicy.liquidGlassEnabled;
      UIRenderPolicy.liquidGlassEnabled = false;
      addTearDown(() {
        UIRenderPolicy.liquidGlassEnabled = previousGlassEnabled;
      });

      const contentBox = SizedBox.expand(key: contentKey);
      await pumpShell(
        tester,
        size: size,
        windowPadding: insets,
        home: AppShellPage(
          tabletKind: tabletKind,
          body: tabletKind == TabletKind.none
              ? contentBox
              : const SafeArea(child: contentBox),
        ),
      );

      final content = tester.getRect(find.byKey(contentKey));
      expect(content.right, size.width - insets.right);
      if (tabletKind == TabletKind.none) {
        final bar = tester.getRect(find.byType(NavigationBar));
        expect(content.left, insets.left);
        expect(content.bottom, bar.top);
        expect(bar.bottom, size.height);
        expect(bar.height, 80 + insets.bottom);
      } else {
        final divider = tester.getRect(find.byType(VerticalDivider));
        expect(content.left, divider.right);
        expect(content.top, insets.top);
        expect(content.bottom, size.height - insets.bottom);
      }
    });
  }
}
