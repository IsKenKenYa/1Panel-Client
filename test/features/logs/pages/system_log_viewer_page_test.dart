import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/pages/system_log_viewer_page.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_viewer.dart';
import 'package:provider/provider.dart';

class _MockLogsService extends Mock implements LogsService {}

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
  late _MockLogsService service;

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
          ChangeNotifierProvider<SystemLogsProvider>(
            create: (_) => SystemLogsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SystemLogViewerPage(
            args: SystemLogViewerArgs(initialFileName: '1Panel.log'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockLogsService();
    when(() => service.loadSystemLogFiles()).thenAnswer(
      (_) async => const <String>['1Panel.log'],
    );
    when(() => service.loadSystemLogContent(
          fileName: any(named: 'fileName'),
          useCoreLogs: any(named: 'useCoreLogs'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          latest: any(named: 'latest'),
        )).thenAnswer(
      (_) async => const FileReadByLineResponse(
        path: '/var/log/1Panel.log',
        lines: <String>['system-line'],
      ),
    );
  });

  testWidgets('SystemLogViewerPage renders selected file and content',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('1Panel.log'), findsWidgets);
    expect(find.byType(LogViewer), findsOneWidget);
  });

  testWidgets(
      'SystemLogViewerPage does not initialize when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.loadSystemLogFiles());
  });
}
