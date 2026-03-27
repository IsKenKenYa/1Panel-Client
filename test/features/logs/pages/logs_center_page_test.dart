import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';
import 'package:onepanel_client/features/logs/pages/logs_center_page.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
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

  setUpAll(() {
    registerFallbackValue(const OperationLogSearchRequest());
    registerFallbackValue(const LoginLogSearchRequest());
    registerFallbackValue(const TaskLogSearch());
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
          ChangeNotifierProvider<LogsProvider>(
            create: (_) => LogsProvider(service: service),
          ),
          ChangeNotifierProvider<TaskLogsProvider>(
            create: (_) => TaskLogsProvider(service: service),
          ),
          ChangeNotifierProvider<SystemLogsProvider>(
            create: (_) => SystemLogsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const LogsCenterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockLogsService();
    when(() => service.searchOperationLogs(any())).thenAnswer(
      (_) async => const PageResult<OperationLogEntry>(
        items: <OperationLogEntry>[],
        total: 0,
      ),
    );
    when(() => service.searchLoginLogs(any())).thenAnswer(
      (_) async => const PageResult<LoginLogEntry>(
        items: <LoginLogEntry>[],
        total: 0,
      ),
    );
    when(() => service.searchTaskLogs(any())).thenAnswer(
      (_) async => const PageResult<TaskLog>(items: <TaskLog>[], total: 0),
    );
    when(() => service.loadExecutingTaskCount()).thenAnswer((_) async => 0);
    when(() => service.loadSystemLogFiles())
        .thenAnswer((_) async => const <String>[]);
  });

  testWidgets('LogsCenterPage renders four tabs', (tester) async {
    await pumpPage(tester);

    expect(find.text('Operation'), findsWidgets);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Task'), findsWidgets);
    expect(find.text('System'), findsWidgets);
  });

  testWidgets('LogsCenterPage does not load when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.searchOperationLogs(any()));
    verifyNever(() => service.searchLoginLogs(any()));
    verifyNever(() => service.searchTaskLogs(any()));
    verifyNever(() => service.loadSystemLogFiles());
  });
}
