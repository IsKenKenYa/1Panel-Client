import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_sidebar.dart';
import 'package:onepanel_client/ui/tablet/app/tablet_shell_page.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/routing/ui_route_host.dart';
import 'package:provider/provider.dart';

Widget _buildHostUnderTest(
  RouteSettings settings, {
  Size size = const Size(390, 844),
  UiTarget? targetOverride,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppSettingsController()),
      ChangeNotifierProvider(create: (_) => ServerProvider()),
      ChangeNotifierProvider(create: (_) => CurrentServerController()),
      ChangeNotifierProvider(create: (_) => PinnedModulesController()),
    ],
    child: MaterialApp(
      home: Align(
        child: SizedBox.fromSize(
          size: size,
          child: UiRouteHost(
            settings: settings,
            debugTargetOverride: targetOverride,
          ),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
    ),
  );
}

void main() {
  group('UiRouteHost', () {
    testWidgets('home on a compact Android window uses bottom navigation',
        (tester) async {
      await tester.pumpWidget(
        _buildHostUnderTest(RouteSettings(name: '/home')),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(AppShellPage), findsOneWidget);
    },
        variant: const TargetPlatformVariant(<TargetPlatform>{
          TargetPlatform.android,
        }));

    testWidgets('tablet home builds TabletShellPage for harmony tablet',
        (tester) async {
      await tester.pumpWidget(
        _buildHostUnderTest(
          const RouteSettings(name: '/home'),
          size: const Size(1200, 900),
          targetOverride: const UiTarget(
            platformKind: UiPlatformKind.harmony,
            formFactor: UiFormFactor.tablet,
            tabletKind: TabletKind.harmonyPad,
          ),
        ),
      );

      expect(find.byType(TabletShellPage), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('unknown route shows not-found scaffold', (tester) async {
      await tester.pumpWidget(
        _buildHostUnderTest(RouteSettings(name: '/__unknown__')),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    },
        variant: const TargetPlatformVariant(<TargetPlatform>{
          TargetPlatform.android,
        }));

    testWidgets('landscape rail and split-screen bottom bar share module state',
        (tester) async {
      const route = RouteSettings(name: '/home');
      await tester.pumpWidget(
        _buildHostUnderTest(route, size: const Size(800, 390)),
      );
      final shell = tester.state(find.byType(AppShellPage));
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.scrollable, isTrue);
      final settingsAction = find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(Icons.settings_outlined),
      );
      await tester.ensureVisible(settingsAction);
      await tester.tap(settingsAction);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.pumpWidget(
        _buildHostUnderTest(route, size: const Size(480, 390)),
      );
      expect(tester.state(find.byType(AppShellPage)), same(shell));
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.android}));

    testWidgets('web keeps the open detail when its navigation changes',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const route = RouteSettings(name: '/home', arguments: 'settings');
      const web = UiTarget(
        platformKind: UiPlatformKind.web,
        formFactor: UiFormFactor.desktop,
      );
      await tester.pumpWidget(_buildHostUnderTest(
        route, size: const Size(1280, 800), targetOverride: web,
      ));
      final settings = AppLocalizations.of(tester.element(find.byType(SettingsPage)));
      final language = find.text(settings.settingsLanguage);
      await tester.ensureVisible(language);
      await tester.tap(language);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSettingsPage), findsOneWidget);
      for (final (width, navigation) in [
        (760.0, TabletShellPage),
        (390.0, NavigationBar),
        (1280.0, DesktopSidebar),
      ]) {
        await tester.pumpWidget(_buildHostUnderTest(
          route, size: Size(width, 700), targetOverride: web,
        ));
        await tester.pumpAndSettle();
        expect(find.byType(navigation), findsOneWidget);
        expect(find.byType(LanguageSettingsPage), findsOneWidget);
      }
    }, variant: const TargetPlatformVariant({TargetPlatform.windows}));
  });
}
