import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/pages/runtime_detail_page.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_detail_provider.dart';
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
  const detail = RuntimeInfo(
    id: 1,
    name: 'node-main',
    type: 'node',
    resource: 'appstore',
    status: 'Running',
    image: 'node:20-alpine',
    codeDir: '/apps/node',
    port: '3000',
    params: <String, dynamic>{'CONTAINER_NAME': 'node-main'},
  );

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
          ChangeNotifierProvider<RuntimeDetailProvider>(
            create: (_) => RuntimeDetailProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const RuntimeDetailPage(
            args: RuntimeDetailArgs(runtimeId: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockRuntimeService();
    when(() => service.getRuntimeDetail(any())).thenAnswer((_) async => detail);
    when(() => service.syncRuntimeStatus()).thenAnswer((_) async {});
    when(() => service.canStart(any())).thenReturn(false);
    when(() => service.canStop(any())).thenReturn(true);
    when(() => service.canRestart(any())).thenReturn(true);
    when(() => service.canEdit(any())).thenReturn(true);
    when(() => service.canOpenAdvanced(any())).thenReturn(true);
  });

  testWidgets('RuntimeDetailPage renders overview tabs', (tester) async {
    await pumpPage(tester);

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('node-main'), findsWidgets);
  });

  testWidgets('RuntimeDetailPage does not load when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.getRuntimeDetail(any()));
  });
}
