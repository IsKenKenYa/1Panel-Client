import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class _MockLogsService extends Mock implements LogsService {}

void main() {
  late _MockLogsService service;
  late LogsProvider provider;

  setUpAll(() {
    registerFallbackValue(const OperationLogSearchRequest());
    registerFallbackValue(const LoginLogSearchRequest());
  });

  setUp(() {
    service = _MockLogsService();
    when(() => service.searchOperationLogs(any())).thenAnswer(
      (_) async => const PageResult<OperationLogEntry>(
        items: <OperationLogEntry>[
          OperationLogEntry(
            id: 1,
            source: 'apps',
            status: 'Success',
            detailEn: 'Deploy app',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.searchLoginLogs(any())).thenAnswer(
      (_) async => const PageResult<LoginLogEntry>(
        items: <LoginLogEntry>[
          LoginLogEntry(
            id: 1,
            ip: '127.0.0.1',
            status: 'Success',
          ),
        ],
        total: 1,
      ),
    );
    provider = LogsProvider(service: service);
  });

  test('loadAll hydrates operation and login logs', () async {
    await provider.loadAll();

    expect(provider.operationItems, hasLength(1));
    expect(provider.loginItems, hasLength(1));
  });

  test('operation filters are forwarded to service request', () async {
    provider.updateOperationKeyword('deploy');
    provider.updateOperationSource('apps');
    provider.updateOperationStatus('Success');

    await provider.loadOperationLogs();

    verify(() => service.searchOperationLogs(const OperationLogSearchRequest(
          operation: 'deploy',
          source: 'apps',
          status: 'Success',
        ))).called(1);
  });
}
