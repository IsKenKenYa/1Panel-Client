import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjobs_provider.dart';
import 'package:onepanel_client/features/databases/databases_page.dart';
import 'package:onepanel_client/features/firewall/firewall_page.dart';
import 'package:onepanel_client/features/group/providers/group_center_provider.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/monitoring/monitoring_page.dart';
import 'package:onepanel_client/features/openresty/openresty_page.dart';
import 'package:onepanel_client/features/operations_center/pages/operations_center_page.dart';
import 'package:onepanel_client/features/processes/providers/processes_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/runtimes_provider.dart';
import 'package:onepanel_client/features/script_library/providers/script_library_provider.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/settings/system_settings_page.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_settings_provider.dart';
import 'package:onepanel_client/features/terminal/terminal_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_center_page.dart';
import 'package:onepanel_client/features/websites/websites_page.dart';
import 'package:onepanel_client/ui/routing/ui_route_host.dart';
import 'package:provider/provider.dart';

void main() {
  group('ServerDetailPage routes', () {
    final rootEntries = <(String, ClientModule, Matcher)>[
      (AppRoutes.files, ClientModule.files, _mobileShell(ClientModule.files)),
      (
        AppRoutes.containers,
        ClientModule.containers,
        _mobileShell(ClientModule.containers),
      ),
      (AppRoutes.apps, ClientModule.apps, isA<AppsPage>()),
      (AppRoutes.websites, ClientModule.websites, isA<WebsitesPage>()),
      (AppRoutes.ai, ClientModule.ai, isA<MultiProvider>()),
      (
        AppRoutes.securityVerification,
        ClientModule.verification,
        isA<SecurityVerificationPage>(),
      ),
    ];
    for (final (name, module, destination) in rootEntries) {
      testWidgets('$name opens the module root', (tester) async {
        await _verifyRoute(
          tester,
          name: name,
          module: module,
          embedded: false,
          destination: destination,
        );
      });
    }

    _verifyServerSubpages({
      AppRoutes.operations: isA<OperationsCenterPage>(),
      AppRoutes.databases: isA<DatabasesPage>(),
      AppRoutes.firewall: isA<FirewallPage>(),
      AppRoutes.terminal: isA<TerminalPage>(),
      AppRoutes.monitoring: isA<MonitoringPage>(),
      AppRoutes.openrestyCenter: isA<OpenRestyPage>(),
    });

    testWidgets('System settings belongs to the settings module',
        (tester) async {
      await _verifyRoute(
        tester,
        name: AppRoutes.systemSettings,
        module: ClientModule.settings,
        embedded: true,
        destination: isA<SystemSettingsPage>(),
      );
    });

    testWidgets('ServerDetailPage receives the selected server',
        (tester) async {
      final server = ServerCardViewModel(
        config: ApiConfig(
          id: 'test-server',
          name: 'Panel',
          url: 'https://panel.example.invalid',
          apiKey: '',
        ),
        isCurrent: true,
        metrics: const ServerMetricsSnapshot(),
      );

      await _verifyRoute(
        tester,
        name: AppRoutes.serverDetail,
        module: ClientModule.servers,
        embedded: true,
        arguments: server,
        destination: isA<ServerDetailPage>()
            .having((page) => page.server, 'server', same(server)),
      );
    });

    testWidgets('ServerDetailPage requires a server argument', (tester) async {
      final context = await _routeContext(tester);
      final route = AppRouter.generateEmbeddedRoute(
        const RouteSettings(name: AppRoutes.serverDetail),
      ) as MaterialPageRoute<dynamic>;
      expect(route.builder(context), isA<NotFoundPage>());
    });
  });

  group('OperationsCenterPage routes', () {
    _verifyServerSubpages({
      AppRoutes.cronjobs: isA<ChangeNotifierProvider<CronjobsProvider>>(),
      AppRoutes.scripts: isA<ChangeNotifierProvider<ScriptLibraryProvider>>(),
      AppRoutes.commands: isA<ChangeNotifierProvider<CommandsProvider>>(),
      AppRoutes.backups: isA<ChangeNotifierProvider<BackupAccountsProvider>>(),
      AppRoutes.runtimes: isA<ChangeNotifierProvider<RuntimesProvider>>(),
      AppRoutes.groupCenter: isA<ChangeNotifierProvider<GroupCenterProvider>>(),
      AppRoutes.hostAssets: isA<ChangeNotifierProvider<HostAssetsProvider>>(),
      AppRoutes.ssh: isA<ChangeNotifierProvider<SshSettingsProvider>>(),
      AppRoutes.processes: isA<ChangeNotifierProvider<ProcessesProvider>>(),
      AppRoutes.logs: isA<MultiProvider>(),
      AppRoutes.toolbox: isA<ToolboxCenterPage>(),
    });
  });
}

void _verifyServerSubpages(Map<String, Matcher> entries) {
  for (final entry in entries.entries) {
    testWidgets('${entry.key} opens inside the servers module', (tester) async {
      await _verifyRoute(
        tester,
        name: entry.key,
        module: ClientModule.servers,
        embedded: true,
        destination: entry.value,
      );
    });
  }
}

Future<void> _verifyRoute(
  WidgetTester tester, {
  required String name,
  required ClientModule module,
  required bool embedded,
  required Matcher destination,
  Object? arguments,
}) async {
  final context = await _routeContext(tester);
  final settings = RouteSettings(name: name, arguments: arguments);
  final target = shellRouteTargetForRoute(name);
  expect(target?.module, module);
  expect(target?.embedRouteInShell, embedded);

  final route = AppRouter.generateRoute(settings) as MaterialPageRoute<dynamic>;
  expect(route.settings, same(settings));
  expect(route.builder(context), destination);

  try {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      final child = route.builder(context);
      expect(child, isA<UiRouteHost>(), reason: platform.name);
      final host = child as UiRouteHost;
      expect(host.settings.name, AppRoutes.home);
      expect(host.settings.arguments, {
        'module': module.storageId,
        if (embedded) 'route': name,
        if (embedded && arguments != null) 'routeArgs': arguments,
      });
    }

    if (embedded) {
      final innerRoute = AppRouter.generateEmbeddedRoute(settings)
          as MaterialPageRoute<dynamic>;
      expect(innerRoute.settings, same(settings));
      expect(innerRoute.builder(context), destination);
    }
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Matcher _mobileShell(ClientModule module) => isA<UiRouteHost>()
    .having((host) => host.settings.name, 'route', AppRoutes.home)
    .having(
      (host) => AppRouter.readInitialModuleId(host.settings.arguments),
      'module',
      module.storageId,
    );

Future<BuildContext> _routeContext(WidgetTester tester) async {
  const routeContextKey = Key('route-context');
  await tester.pumpWidget(
    const MaterialApp(home: SizedBox.shrink(key: routeContextKey)),
  );
  return tester.element(find.byKey(routeContextKey));
}
