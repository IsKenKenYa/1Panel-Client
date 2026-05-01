import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/operations_center/pages/operations_center_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get isLoading => false;

  @override
  bool get hasServer => true;

  @override
  List<ApiConfig> get servers => <ApiConfig>[_config];

  @override
  ApiConfig? get currentServer => _config;

  @override
  String? get currentServerId => _config.id;

  @override
  Future<void> refresh() async {}
}

void main() {
  Future<void> scrollToKey(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OperationsCenterPage exposes phase-one entry cards',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: FakeCurrentServerController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const OperationsCenterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations Center'), findsOneWidget);
    const automationSectionKey = Key(OperationsCenterPage.automationSectionKey);
    const runtimeSectionKey = Key(OperationsCenterPage.runtimeSectionKey);
    const systemSectionKey = Key(OperationsCenterPage.systemSectionKey);
    const commandsEntryKey = Key(OperationsCenterPage.commandsEntryKey);
    const runtimesEntryKey = Key(OperationsCenterPage.runtimesEntryKey);
    const groupsEntryKey = Key(OperationsCenterPage.groupsEntryKey);
    const hostAssetsEntryKey = Key(OperationsCenterPage.hostAssetsEntryKey);
    const toolboxEntryKey = Key(OperationsCenterPage.toolboxEntryKey);

    expect(find.byKey(automationSectionKey), findsOneWidget);
    expect(find.byKey(commandsEntryKey), findsOneWidget);

    await scrollToKey(tester, runtimeSectionKey);
    expect(find.byKey(runtimeSectionKey), findsOneWidget);
    expect(find.byKey(runtimesEntryKey), findsOneWidget);

    await scrollToKey(tester, systemSectionKey);
    expect(find.byKey(systemSectionKey), findsOneWidget);

    await scrollToKey(tester, groupsEntryKey);
    expect(find.byKey(groupsEntryKey), findsOneWidget);

    await scrollToKey(tester, hostAssetsEntryKey);
    expect(find.byKey(hostAssetsEntryKey), findsOneWidget);

    await scrollToKey(tester, toolboxEntryKey);
    expect(find.byKey(toolboxEntryKey), findsOneWidget);
  });

  testWidgets('OperationsCenterPage uses grid layout on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: FakeCurrentServerController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const OperationsCenterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsWidgets);
  });
}
