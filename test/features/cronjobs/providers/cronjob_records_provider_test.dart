import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_records_provider.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_service.dart';

class _MockCronjobService extends Mock implements CronjobService {}

void main() {
  late _MockCronjobService service;
  late CronjobRecordsProvider provider;

  const record = CronjobRecordInfo(
    id: 11,
    taskId: 'task-1',
    startTime: '2026-03-27 00:00:00',
    status: 'Success',
    message: 'finished',
    targetPath: '/tmp/result',
    interval: 80,
    file: 'record.log',
  );

  setUpAll(() {
    registerFallbackValue(const CronjobRecordQuery(cronjobId: 1));
    registerFallbackValue(
      const CronjobRecordCleanRequest(cronjobId: 1),
    );
  });

  setUp(() {
    service = _MockCronjobService();
    when(() => service.searchRecords(any())).thenAnswer(
      (_) async => const PageResult<CronjobRecordInfo>(
        items: <CronjobRecordInfo>[record],
        total: 1,
      ),
    );
    when(() => service.loadRecordLog(any()))
        .thenAnswer((_) async => 'record log content');
    when(() => service.cleanRecords(any())).thenAnswer((_) async {});
    provider = CronjobRecordsProvider(service: service);
  });

  test('load fetches records', () async {
    await provider.load(1);

    expect(provider.items, hasLength(1));
    expect(provider.statusFilter, isEmpty);
  });

  test('loadRecordLog stores selected log', () async {
    await provider.loadRecordLog(11);

    expect(provider.selectedRecordId, 11);
    expect(provider.selectedLog, 'record log content');
  });

  test('cleanRecords calls service and reloads', () async {
    await provider.load(1);
    clearInteractions(service);
    when(() => service.searchRecords(any())).thenAnswer(
      (_) async => const PageResult<CronjobRecordInfo>(
        items: <CronjobRecordInfo>[record],
        total: 1,
      ),
    );

    final result = await provider.cleanRecords(
      cleanData: true,
      cleanRemoteData: false,
    );

    expect(result, isTrue);
    verify(
      () => service.cleanRecords(
        const CronjobRecordCleanRequest(
          cronjobId: 1,
          cleanData: true,
          cleanRemoteData: false,
        ),
      ),
    ).called(1);
    verify(() => service.searchRecords(any())).called(1);
  });
}
