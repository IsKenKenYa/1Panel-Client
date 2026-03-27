import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/repositories/logs_repository.dart';

class _MockLogsV2Api extends Mock implements LogsV2Api {}

class _MockFileV2Api extends Mock implements FileV2Api {}

void main() {
  late _MockLogsV2Api logsApi;
  late _MockFileV2Api fileApi;
  late LogsRepository repository;

  setUp(() {
    logsApi = _MockLogsV2Api();
    fileApi = _MockFileV2Api();
    repository = LogsRepository(logsApi: logsApi, fileApi: fileApi);
  });

  test('loadSystemLogFiles proxies logs api result', () async {
    when(() => logsApi.getSystemLogFiles()).thenAnswer(
      (_) async => Response<List<String>>(
        data: const <String>['1Panel.log'],
        requestOptions: RequestOptions(path: '/logs/system/files'),
      ),
    );

    final result = await repository.loadSystemLogFiles();

    expect(result, const <String>['1Panel.log']);
  });

  test('readLogLines proxies file api readByLine result', () async {
    const request = FileReadByLineRequest(
      type: 'task',
      taskId: 'task-1',
    );
    when(() => fileApi.readFileByLine(request)).thenAnswer(
      (_) async => Response<FileReadByLineResponse>(
        data: const FileReadByLineResponse(
          path: '/tmp/task-1.log',
          total: 1,
          totalLines: 2,
          lines: <String>['line-1', 'line-2'],
        ),
        requestOptions: RequestOptions(path: '/files/read'),
      ),
    );

    final result = await repository.readLogLines(request);

    expect(result.path, '/tmp/task-1.log');
    expect(result.lines, const <String>['line-1', 'line-2']);
    expect(result.totalLines, 2);
  });
}
