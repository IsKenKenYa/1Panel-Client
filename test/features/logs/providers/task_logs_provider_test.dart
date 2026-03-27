import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class _MockLogsService extends Mock implements LogsService {}

void main() {
  late _MockLogsService service;
  late TaskLogsProvider provider;

  setUpAll(() {
    registerFallbackValue(const TaskLogSearch());
  });

  setUp(() {
    service = _MockLogsService();
    when(() => service.searchTaskLogs(any())).thenAnswer(
      (_) async => const PageResult<TaskLog>(
        items: <TaskLog>[
          TaskLog(
            id: 'task-1',
            name: 'Sync scripts',
            type: 'script',
            status: 'Executing',
            currentStep: 'Pull',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.loadExecutingTaskCount()).thenAnswer((_) async => 2);
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
        lines: <String>['line-1', 'line-2'],
      ),
    );
    provider = TaskLogsProvider(service: service);
  });

  test('load hydrates task logs and executing count', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
    expect(provider.executingCount, 2);
  });

  test('initializeDetail loads task log content', () async {
    await provider.initializeDetail(
      const TaskLogDetailArgs(
        taskId: 'task-1',
        taskName: 'Sync scripts',
        taskType: 'script',
        status: 'Executing',
      ),
    );

    expect(provider.detailContent, 'line-1\nline-2');
    expect(provider.detailPath, '/tmp/task-1.log');
  });

  test('initializeDetail marks missing task id as localized error code',
      () async {
    await provider.initializeDetail(
      const TaskLogDetailArgs(
        taskId: '',
        taskName: 'Broken task',
        taskType: 'script',
        status: 'Failed',
      ),
    );

    expect(provider.detailError, 'logs.task.missingTaskId');
  });
}
