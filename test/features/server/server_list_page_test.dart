import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class TestServerProvider extends ServerProvider {
  TestServerProvider({this.items = const []});

  final List<ServerCardViewModel> items;

  @override
  bool get isLoading => false;

  @override
  List<ServerCardViewModel> get servers => items;

  @override
  Future<void> load() async {
    notifyListeners();
  }

  @override
  Future<void> loadMetrics() async {}
}

void main() {
  testWidgets('coach mark highlight aligns with add button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final currentServer = CurrentServerController();
    await currentServer.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider<CurrentServerController>.value(
              value: currentServer),
          ChangeNotifierProvider<ServerProvider>.value(
              value: TestServerProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ServerListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your first server'), findsOneWidget);
    final addButton = find.byIcon(Icons.add_circle_outline);
    final highlight = find.byKey(const Key('coachmark-highlight'));
    expect(addButton, findsOneWidget);
    expect(highlight, findsOneWidget);

    final addRect = tester.getRect(addButton);
    final highlightRect = tester.getRect(highlight);

    expect((addRect.center.dx - highlightRect.center.dx).abs(), lessThan(2.0));
    expect((addRect.center.dy - highlightRect.center.dy).abs(), lessThan(2.0));
    expect(highlightRect.width, greaterThan(addRect.width));
    expect(highlightRect.height, greaterThan(addRect.height));
  });

  testWidgets('mobile server list renders populated cards without exceptions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final currentServer = CurrentServerController();
    await currentServer.load();

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final serverItems = <ServerCardViewModel>[
      ServerCardViewModel(
        config: ApiConfig(
          id: 'server-1',
          name: 'Tencent Guangzhou',
          url: 'http://10.0.0.1:11451',
          apiKey: 'key-1',
          allowInsecureTls: true,
          isDefault: true,
        ),
        isCurrent: true,
        metrics: const ServerMetricsSnapshot(
          cpuPercent: 0.9,
          memoryPercent: 35.2,
          diskPercent: 71.6,
          load: 0.03,
        ),
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider<CurrentServerController>.value(
              value: currentServer),
          ChangeNotifierProvider<ServerProvider>.value(
            value: TestServerProvider(items: serverItems),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ServerListPage(enableCoach: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tencent Guangzhou'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
