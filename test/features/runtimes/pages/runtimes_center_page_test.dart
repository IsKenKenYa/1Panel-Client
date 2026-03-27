import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/pages/runtimes_center_page.dart';
import 'package:onepanel_client/features/runtimes/providers/runtimes_provider.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockRuntimeService extends Mock implements RuntimeService {}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;
}

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  late _MockRuntimeService service;

  setUpAll(() {
    registerFallbackValue(const RuntimeInfo());
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    CurrentServerController? serverController,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: serverController ?? _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<RuntimesProvider>(
            create: (_) => RuntimesProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const RuntimesCenterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockRuntimeService();
    when(
      () => service.searchRuntimes(
        type: any(named: 'type'),
        name: any(named: 'name'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const PageResult<RuntimeInfo>(
        items: <RuntimeInfo>[
          RuntimeInfo(
            id: 1,
            name: 'php-main',
            type: 'php',
            status: 'Running',
            resource: 'appstore',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.syncRuntimeStatus()).thenAnswer((_) async {});
    when(() => service.operateRuntime(any(), any())).thenAnswer((_) async {});
    when(() => service.deleteRuntime(any())).thenAnswer((_) async {});
    when(() => service.canStart(any())).thenReturn(false);
    when(() => service.canStop(any())).thenReturn(true);
    when(() => service.canRestart(any())).thenReturn(true);
    when(() => service.canEdit(any())).thenReturn(true);
  });

  testWidgets('RuntimesCenterPage renders category chips and runtime card',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('PHP'), findsWidgets);
    expect(find.text('Node'), findsWidgets);
    expect(find.text('php-main'), findsOneWidget);
  });

  testWidgets('RuntimesCenterPage does not load when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.searchRuntimes(
          type: any(named: 'type'),
          name: any(named: 'name'),
          status: any(named: 'status'),
        ));
  });
}
