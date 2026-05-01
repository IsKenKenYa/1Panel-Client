import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TestServerProvider extends ServerProvider {
  TestServerProvider(this._items);

  final List<ServerCardViewModel> _items;
  int loadCallCount = 0;
  int loadMetricsCallCount = 0;

  @override
  List<ServerCardViewModel> get servers => _items;

  @override
  Future<void> load() async {
    loadCallCount += 1;
  }

  @override
  Future<void> loadMetrics() async {
    loadMetricsCallCount += 1;
  }
}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 's1',
    name: 'Demo',
    url: 'https://demo.test',
    apiKey: 'key',
  );

  @override
  ApiConfig? get currentServer => _config;

  @override
  String? get currentServerId => _config.id;

  @override
  bool get hasServer => true;
}

class _FakePinnedModulesController extends PinnedModulesController {
  final List<ClientModule> _pins = const <ClientModule>[
    ClientModule.files,
    ClientModule.containers,
  ];

  @override
  bool get isLoaded => true;

  @override
  List<ClientModule> get pins => List<ClientModule>.unmodifiable(_pins);

  @override
  ClientModule get primaryPin => _pins.first;

  @override
  ClientModule get secondaryPin => _pins.last;

  @override
  List<ClientModule> get options =>
      List<ClientModule>.unmodifiable(kPinnableClientModules);
}

({
  CurrentServerController currentServer,
  PinnedModulesController pinned,
  TestServerProvider provider,
  ServerCardViewModel server,
}) _prepareState() {
  final server = ServerCardViewModel(
    config: ApiConfig(
      id: 's1',
      name: 'Demo',
      url: 'https://demo.test',
      apiKey: 'key',
    ),
    isCurrent: true,
    metrics: const ServerMetricsSnapshot(cpuPercent: 12.3),
  );

  return (
    currentServer: _FakeCurrentServerController(),
    pinned: _FakePinnedModulesController(),
    provider: TestServerProvider([server]),
    server: server,
  );
}

void main() {
  testWidgets(
      'ServerDetailPage uses launcher sections instead of old grid cards',
      (tester) async {
    final state = _prepareState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
              value: state.currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(
              value: state.pinned),
          ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerDetailPage(server: state.server),
        ),
      ),
    );
    await tester.pump();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ServerDetailPage)));

    expect(find.byType(GridView), findsNothing);
    expect(find.text('Bottom Tabs'), findsOneWidget);
    expect(find.text('Edit Tabs'), findsOneWidget);
    expect(find.text('Files', skipOffstage: false), findsWidgets);
    expect(find.text(l10n.serverModuleWebsites, skipOffstage: false),
        findsOneWidget);
    expect(find.text(l10n.serverModuleAi, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'ServerDetailPage refresh action reloads provider and shows feedback',
      (tester) async {
    final state = _prepareState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
              value: state.currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(
              value: state.pinned),
          ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerDetailPage(server: state.server),
        ),
      ),
    );
    await tester.pump();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ServerDetailPage)));
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.serverActionRefresh));
    await tester.pump();

    expect(state.provider.loadCallCount, 1);
    expect(state.provider.loadMetricsCallCount, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(l10n.commonRefresh), findsWidgets);
  });

  testWidgets('ServerDetailPage opens system settings entry route',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = _prepareState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
              value: state.currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(
              value: state.pinned),
          ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: <String, WidgetBuilder>{
            AppRoutes.systemSettings: (_) =>
                const Scaffold(body: Text('system-settings-target')),
          },
          home: ServerDetailPage(server: state.server),
        ),
      ),
    );
    await tester.pump();

    final l10n =
        AppLocalizations.of(tester.element(find.byType(ServerDetailPage)));
    final target = find.widgetWithText(
      ListTile,
      l10n.serverModuleSystemSettings,
    );
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      target,
    );
    await tester.pumpAndSettle();

    expect(find.text('system-settings-target'), findsOneWidget);
  });
}
