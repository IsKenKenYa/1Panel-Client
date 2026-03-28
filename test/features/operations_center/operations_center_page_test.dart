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
    expect(
      find.byKey(
        const Key(OperationsCenterPage.automationSectionKey),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(OperationsCenterPage.commandsEntryKey),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key(OperationsCenterPage.runtimeSectionKey)),
      200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const Key(OperationsCenterPage.runtimesEntryKey),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key(OperationsCenterPage.hostAssetsEntryKey)),
      200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const Key(OperationsCenterPage.groupsEntryKey),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(OperationsCenterPage.hostAssetsEntryKey),
      ),
      findsOneWidget,
    );
  });
}
