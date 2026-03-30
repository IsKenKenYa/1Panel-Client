import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class TestServerProvider extends ServerProvider {
  TestServerProvider(this._items);

  final List<ServerCardViewModel> _items;

  @override
  List<ServerCardViewModel> get servers => _items;

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMetrics() async {}
}

void main() {
  testWidgets(
      'ServerDetailPage uses launcher sections instead of old grid cards',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'api_configs': jsonEncode([
        ApiConfig(
          id: 's1',
          name: 'Demo',
          url: 'https://demo.test',
          apiKey: 'key',
        ).toJson(),
      ]),
      'current_api_config_id': 's1',
    });

    final currentServer = CurrentServerController();
    final pinned = PinnedModulesController();
    await currentServer.load();
    await pinned.load();

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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
              value: currentServer),
          ChangeNotifierProvider<PinnedModulesController>.value(value: pinned),
          ChangeNotifierProvider<ServerProvider>.value(
            value: TestServerProvider([server]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerDetailPage(server: server),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n =
      AppLocalizations.of(tester.element(find.byType(ServerDetailPage)));

    expect(find.byType(GridView), findsNothing);
    expect(find.text('Bottom Tabs'), findsOneWidget);
    expect(find.text('Edit Tabs'), findsOneWidget);
    expect(find.text('Files'), findsWidgets);
    expect(find.text(l10n.serverModuleWebsites), findsOneWidget);
    expect(find.text(l10n.serverModuleAi), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.serverModuleSystemSettings),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.serverModuleSystemSettings), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Operations Center'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Operations Center'), findsWidgets);
    expect(find.text('Experimental'), findsWidgets);
  });
}
