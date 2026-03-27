import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class _MockLogsService extends Mock implements LogsService {}

void main() {
  late _MockLogsService service;
  late SystemLogsProvider provider;

  setUp(() {
    service = _MockLogsService();
    when(() => service.loadSystemLogFiles()).thenAnswer(
      (_) async => const <String>['1Panel.log', '1Panel-Core.log'],
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
        lines: <String>['line-1'],
      ),
    );
    provider = SystemLogsProvider(service: service);
  });

  test('loadFiles selects first file when none is preset', () async {
    await provider.loadFiles();

    expect(provider.files, hasLength(2));
    expect(provider.selectedFile, '1Panel.log');
  });

  test('initialize loads selected file content', () async {
    await provider.initialize(
      const SystemLogViewerArgs(initialFileName: '1Panel.log'),
    );

    expect(provider.selectedFile, '1Panel.log');
    expect(provider.content, 'line-1');
  });

  test('updateSource reloads content with core flag', () async {
    await provider.initialize(
      const SystemLogViewerArgs(initialFileName: '1Panel.log'),
    );

    await provider.updateSource(SystemLogSource.core);

    verify(() => service.loadSystemLogContent(
          fileName: '1Panel.log',
          useCoreLogs: true,
          page: 1,
          pageSize: 200,
          latest: true,
        )).called(greaterThan(0));
  });
}
