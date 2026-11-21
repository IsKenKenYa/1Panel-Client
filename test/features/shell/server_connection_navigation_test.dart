import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/features/shell/connection_service_providers.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/websites/websites_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('cached API services follow the persisted connection revision',
      (tester) async {
    final providers = connectionServiceProviders();
    final revision = ValueNotifier('first');
    addTearDown(revision.dispose);
    late (AppService, DashboardProvider, WebsitesProvider) services;
    await tester.pumpWidget(ValueListenableBuilder<String>(
      valueListenable: revision,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
          ...providers,
        ],
        child: Builder(builder: (context) {
          services = (
            context.watch<AppService>(),
            context.watch<DashboardProvider>(),
            context.watch<WebsitesProvider>(),
          );
          return const SizedBox.shrink();
        }),
      ),
      builder: (_, value, child) => Provider<(String?, String?)>.value(
        value: ('server', value),
        child: child,
      ),
    ));
    final previous = services;
    revision.value = 'second';
    await tester.pump();
    expect(services.$1, isNot(same(previous.$1)));
    expect(services.$2, isNot(same(previous.$2)));
    expect(services.$3, isNot(same(previous.$3)));
    expect(previous.$2.isDisposed, isTrue);
    expect(previous.$3.isDisposed, isTrue);
  });

  test('initial loading preserves links and a new revision clears panel links', () {
    final detail = ShellEmbeddedRoute(AppRoutes.databaseDetail, 42);
    final settings = ShellEmbeddedRoute(AppRoutes.settingsLanguage, null);
    final servers = ShellEmbeddedRoute(AppRoutes.serverDetail, 'server');
    for (final route in [detail, settings, servers]) {
      route.updateConnection(null, null);
      route.updateConnection('server', 'first');
      route.updateConnection('server', 'first');
    }
    expect(detail.name, AppRoutes.databaseDetail);
    expect(detail.arguments, 42);
    for (final route in [detail, settings, servers]) {
      route.updateConnection('server', 'second');
    }
    expect(detail.name, isNull);
    expect(detail.arguments, isNull);
    expect(settings.name, AppRoutes.settingsLanguage);
    expect(servers.name, AppRoutes.serverDetail);
  });

  testWidgets('same-ID edits reset only module roots that use the server',
      (tester) async {
    await tester.pumpWidget(Builder(builder: (context) {
      for (final module in ClientModule.values) {
        Key? key(String revision) => ModuleRegistry.buildShellPage(
              context,
              module,
              serverId: 'server',
              serverRevision: revision,
            ).key;
        expect(key('first') == key('second'), !module.requiresServer);
        expect(key('second'), key('second'));
      }
      return const SizedBox.shrink();
    }));
  });

  testWidgets('connection change removes panel details and anonymous children',
      (tester) async {
    final routes = ServerRouteObserver();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [routes],
      home: const SizedBox.shrink(),
    ));
    routes.updateConnection('server', 'first');
    Future<void> push(String? name, String text) async {
      navigator.currentState!.push<void>(MaterialPageRoute(
        settings: RouteSettings(name: name),
        builder: (_) => Text(text),
      ));
      await tester.pumpAndSettle();
    }

    await push(AppRoutes.serverDetail, 'servers');
    await push(AppRoutes.databaseDetail, 'database');
    await push(null, 'editor');
    routes.updateConnection('server', 'first');
    await tester.pump();
    expect(find.text('editor'), findsOneWidget);
    routes.updateConnection('server', 'second');
    await tester.pumpAndSettle();
    expect(find.text('servers'), findsOneWidget);
    expect(find.text('editor', skipOffstage: false), findsNothing);
    expect(find.text('database', skipOffstage: false), findsNothing);
    await push(AppRoutes.settingsLanguage, 'language');
    routes.updateConnection('another', 'third');
    await tester.pumpAndSettle();
    expect(find.text('language'), findsOneWidget);
  });

  testWidgets('a root dialog inherits the active inner detail connection',
      (tester) async {
    final lockTarget = ValueNotifier<String?>(null);
    addTearDown(lockTarget.dispose);
    final outer = ServerRouteObserver(isAppNavigator: true, lockTarget: lockTarget);
    final inner = ServerRouteObserver();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [outer],
      home: Builder(builder: (context) {
        inner.setParent(context, active: true);
        return Navigator(
          key: navigator,
          observers: [inner],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const Text('module')),
        );
      }),
    ));
    outer.updateConnection('server', 'first');
    inner.updateConnection('server', 'first');
    navigator.currentState!.push<void>(MaterialPageRoute(
      settings: const RouteSettings(name: AppRoutes.containerDetail),
      builder: (_) => const Text('detail'),
    ));
    await tester.pumpAndSettle();
    expect(lockTarget.value, ClientModule.containers.storageId);
    showDialog<void>(
      context: tester.element(find.text('detail')),
      builder: (_) => const AlertDialog(title: Text('confirmation')),
    );
    await tester.pumpAndSettle();
    expect(lockTarget.value, ClientModule.containers.storageId);
    outer.updateConnection('server', 'second');
    inner.updateConnection('server', 'second');
    await tester.pumpAndSettle();
    expect(find.text('confirmation', skipOffstage: false), findsNothing);
    expect(find.text('detail', skipOffstage: false), findsNothing);
    expect(find.text('module'), findsOneWidget);
    expect(lockTarget.value, isNull);
  });
}
