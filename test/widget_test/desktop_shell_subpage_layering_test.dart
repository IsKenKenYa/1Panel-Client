import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/server_repository.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/settings/legal_center_page.dart';
import 'package:onepanel_client/features/settings/mainland_sdk_disclosure_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_content_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_routed_module_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/shell_content_host.dart';

void main() {
  testWidgets('设置深层链接在同一内容区域逐级返回', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppSettingsController(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DesktopContentHost(
          module: ClientModule.settings,
          serverId: null,
          embeddedRoute: AppRoutes.settingsMainlandSdkDisclosure,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MainlandSdkDisclosurePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LegalCenterPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('embedded route changes replace only the inner navigator',
      (tester) async {
    Future<NavigatorState> showRoute(String route) async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppSettingsController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DesktopRoutedModuleHost(routeName: route),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.state<NavigatorState>(find.descendant(
        of: find.byType(DesktopRoutedModuleHost),
        matching: find.byType(Navigator),
      ));
    }

    final initial = await showRoute(AppRoutes.settingsLegalCenter);
    expect(find.byType(LegalCenterPage), findsOneWidget);
    expect(await showRoute(AppRoutes.settingsLegalCenter), same(initial));
    expect(await showRoute(AppRoutes.settingsLanguage), isNot(same(initial)));
    expect(find.byType(LanguageSettingsPage), findsOneWidget);
  });

  group('ShellContentHost.embeddedRoute branches', () {
    testWidgets(
      'returns DesktopRoutedModuleHost when embeddedRoute is non-null',
      (tester) async {
        final serverProvider = ServerProvider(
          repository: _NoopServerRepository(),
        );
        addTearDown(serverProvider.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServerProvider>.value(
                value: serverProvider,
              ),
              ChangeNotifierProvider(
                create: (_) => CurrentServerController(),
              ),
              ChangeNotifierProvider(
                create: (_) => AppSettingsController(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('zh')],
              home: Scaffold(
                body: ShellContentHost(
                  module: ClientModule.servers,
                  serverId: null,
                  embeddedRoute: '/some/route',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The embedded-route branch must build a DesktopRoutedModuleHost
        // (it owns its own Navigator) and NOT the module-root Navigator
        // owned by the ShellContentHost's per-instance key.
        expect(find.byType(DesktopRoutedModuleHost), findsOneWidget);
        expect(
            findShellContentNavigator(
              tester.element(find.byType(ShellContentHost)),
            ),
            isNull);
      },
    );
  });

  group('DesktopContentHost branches', () {
    testWidgets(
      'builds the IndexedStack-based ShellContentHost host when '
      'embeddedRoute is null',
      (tester) async {
        final serverProvider = ServerProvider(
          repository: _NoopServerRepository(),
        );
        addTearDown(serverProvider.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServerProvider>.value(
                value: serverProvider,
              ),
              ChangeNotifierProvider(
                create: (_) => CurrentServerController(),
              ),
              ChangeNotifierProvider(
                create: (_) => AppSettingsController(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('zh')],
              home: const Scaffold(
                body: DesktopContentHost(
                  module: ClientModule.servers,
                  serverId: null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No embedded route -> must use the indexed Stack of cached
        // ShellContentHost entries, each owning its own per-instance
        // Navigator key. The `findShellContentNavigator` helper walks
        // *up* the tree from a caller's context, so we hand it the
        // ShellContentHost's own element here.
        expect(find.byType(ShellContentHost), findsOneWidget);
        expect(find.byType(IndexedStack), findsOneWidget);
        expect(
          findShellContentNavigator(
            tester.element(find.byType(ShellContentHost)),
          ),
          isNotNull,
        );
      },
    );
  });

  group('openRouteRespectingShell fallback (source-based)', () {
    test(
      'falls back to pushReplacementNamed(AppRoutes.home) when the inner '
      'navigator is unavailable',
      () async {
        final source = await File(
          'lib/features/shell/shell_navigation.dart',
        ).readAsString();

        // The fallback path is taken when the inner navigator returns null
        // (e.g. mid-build, or no ShellContentHost mounted yet).
        expect(
          source,
          matches(
            r'Navigator\.of\(context, rootNavigator: true\)\s*'
            r'\.pushReplacementNamed\(\s*AppRoutes\.home,',
          ),
          reason: 'The home route must open in the root Navigator',
        );
      },
    );
  });
}

/// No-op replacement for [ServerRepository] used by the test only — it
/// returns an empty server list without touching storage or network.
class _NoopServerRepository extends ServerRepository {
  const _NoopServerRepository();

  @override
  Future<List<ServerCardViewModel>> loadServerCards({
    bool withMetrics = false,
  }) async =>
      const <ServerCardViewModel>[];

  @override
  Future<ServerMetricsSnapshot> loadMetricsForConfig(ApiConfig config) async =>
      const ServerMetricsSnapshot();

  @override
  Future<void> setCurrent(String id) async {}

  @override
  Future<void> removeConfig(String id) async {}

  @override
  Future<void> saveConfig(ApiConfig config) async {}
}
