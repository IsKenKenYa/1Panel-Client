import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/pages/task_log_detail_page.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
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
  const args = TaskLogDetailArgs(
    taskId: 'task-1',
    taskName: 'Sync scripts',
    taskType: 'script',
    status: 'Executing',
    currentStep: 'Pull',
    logFile: '/tmp/task-1.log',
    createdAt: '2026-03-27 10:00:00',
  );

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
          ChangeNotifierProvider<TaskLogsProvider>(
            create: (_) => TaskLogsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TaskLogDetailPage(args: args),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockLogsService();
    when(() => service.loadTaskLogContent(
          taskId: any(named: 'taskId'),
          taskType: any(named: 'taskType'),
          taskOperate: any(named: 'taskOperate'),
          resourceId: any(named: 'resourceId'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          latest: any(named: 'latest'),
        )).thenAnswer(
      (_) async => const FileReadByLineResponse(
        path: '/tmp/task-1.log',
        lines: <String>['task-line'],
      ),
    );
  });

  testWidgets('TaskLogDetailPage renders metadata and content', (tester) async {
    await pumpPage(tester);

    expect(find.text('Sync scripts'), findsOneWidget);
    expect(find.byType(LogViewer), findsOneWidget);
  });

  testWidgets('TaskLogDetailPage does not initialize when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.loadTaskLogContent(
          taskId: any(named: 'taskId'),
          taskType: any(named: 'taskType'),
          taskOperate: any(named: 'taskOperate'),
          resourceId: any(named: 'resourceId'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          latest: any(named: 'latest'),
        ));
  });
}
