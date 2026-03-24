import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanelapp_app/core/services/app_settings_controller.dart';
import 'package:onepanelapp_app/core/theme/theme_controller.dart';
import 'package:onepanelapp_app/features/server/server_provider.dart';
import 'package:onepanelapp_app/features/shell/app_shell_page.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
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
          home: const AppShellPage(),
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
    expect(find.text('App Management'), findsWidgets);
    expect(find.text('Websites'), findsWidgets);
    expect(find.text('Security'), findsWidgets);
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
}
