import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/panels/one_panel_module_sections.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/widgets/server_detail_header_card.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

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

({
  CurrentServerController currentServer,
  PinnedModulesController pinned,
  ServerProvider provider,
  ApiConfig server,
})
_prepareState() {
  final server = ApiConfig(
    id: 's1',
    name: 'Demo',
    url: 'https://demo.test',
    apiKey: 'key',
  );

  return (
    currentServer: CurrentServerController(),
    pinned: PinnedModulesController(),
    provider: ServerProvider()..syncDirectory([server], server.id),
    server: server,
  );
}

void main() {
  testWidgets('server actions are accessible in a narrow detail pane', (
    tester,
  ) async {
    final server = ApiConfig(
      id: 'local',
      name: 'Lab',
      url: 'https://lab.example',
      apiKey: '',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ServerProvider()..syncDirectory([server], server.id),
          ),
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
          ChangeNotifierProvider(create: (_) => PinnedModulesController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(2)),
                  child: TickerMode(
                    enabled: false,
                    child: ServerDetailPage(server: server),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ServerDetailPage)),
    );
    expect(
      find
          .descendant(
            of: find.byType(ServerSwitcherAction),
            matching: find.byType(IconButton),
          )
          .hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(l10n.commonMore).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text(l10n.commonEdit).hitTestable(), findsOneWidget);
    expect(find.text(l10n.commonDelete).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未注册的面板保留服务器信息并显示类型提示', (tester) async {
    final server = ApiConfig(
      id: 'other',
      name: 'Lab',
      url: 'https://example.org',
      panelType: 'unregistered',
      apiKey: '',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ServerProvider()..syncDirectory([server], server.id),
          ),
          ChangeNotifierProvider(create: (_) => CurrentServerController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerDetailPage(server: server),
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ServerDetailPage)),
    );
    expect(find.text('Lab'), findsOneWidget);
    expect(
      find.text(l10n.serverPanelUnavailable('unregistered')),
      findsOneWidget,
    );
    expect(find.byType(OnePanelModuleSections), findsNothing);
  });

  testWidgets(
    'ServerDetailPage uses launcher sections instead of old grid cards',
    (tester) async {
      final state = _prepareState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CurrentServerController>.value(
              value: state.currentServer,
            ),
            ChangeNotifierProvider<PinnedModulesController>.value(
              value: state.pinned,
            ),
            ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TickerMode(
              enabled: false,
              child: ServerDetailPage(server: state.server),
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ServerDetailPage)),
      );

      expect(find.byType(GridView), findsNothing);
      expect(find.text('Bottom Tabs'), findsOneWidget);
      expect(find.text('Edit Tabs'), findsOneWidget);
      expect(find.text('Files', skipOffstage: false), findsWidgets);
      expect(
        find.text(l10n.serverModuleWebsites, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(l10n.serverModuleAi, skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets('其他服务器的目录更新保留当前详情头卡和模块', (tester) async {
    final state = _prepareState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: state.currentServer,
          ),
          ChangeNotifierProvider<PinnedModulesController>.value(
            value: state.pinned,
          ),
          ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TickerMode(
            enabled: false,
            child: ServerDetailPage(server: state.server),
          ),
        ),
      ),
    );
    await tester.pump();

    final header = tester.widget<ServerDetailHeaderCard>(
      find.byType(ServerDetailHeaderCard),
    );
    final modules = tester.widget<OnePanelModuleSections>(
      find.byType(OnePanelModuleSections),
    );
    state.provider.syncDirectory([
      state.server,
      ApiConfig(
        id: 'other',
        name: 'Other',
        url: 'https://other.example',
        apiKey: '',
      ),
    ], state.server.id);
    await tester.pump();
    expect(tester.widget(find.byType(ServerDetailHeaderCard)), same(header));
    expect(tester.widget(find.byType(OnePanelModuleSections)), same(modules));
  });

  testWidgets('ServerDetailPage opens system settings entry route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = _prepareState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>(
            create: (_) => _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<PinnedModulesController>.value(
            value: state.pinned,
          ),
          ChangeNotifierProvider<ServerProvider>.value(value: state.provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: <String, WidgetBuilder>{
            AppRoutes.systemSettings: (_) =>
                const Scaffold(body: Text('system-settings-target')),
          },
          home: TickerMode(
            enabled: false,
            child: ServerDetailPage(server: state.server),
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ServerDetailPage)),
    );
    final target = find.widgetWithText(
      ListTile,
      l10n.serverModuleSystemSettings,
    );
    // ensureVisible 按目标实际位置滚动；固定增量的 scrollUntilVisible
    // 在入口列表超出一屏时会越过目标导致点击落空。
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.text('system-settings-target'), findsOneWidget);
  });
}
