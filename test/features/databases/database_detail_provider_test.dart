import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';

class _FakeDetailService extends DatabasesService {
  _FakeDetailService({
    required this.detail,
    this.throwOnUpdateDescription = false,
  });

  final DatabaseDetailData detail;
  final bool throwOnUpdateDescription;

  int loadDetailCallCount = 0;
  int updateDescriptionCallCount = 0;
  String? lastDescription;

  @override
  Future<DatabaseDetailData> loadDetail(DatabaseListItem item) async {
    loadDetailCallCount += 1;
    return detail;
  }

  @override
  Future<void> updateDescription(
    DatabaseListItem item,
    String description,
  ) async {
    updateDescriptionCallCount += 1;
    lastDescription = description;
    if (throwOnUpdateDescription) {
      throw Exception('update failed');
    }
  }
}

void main() {
  const mysqlItem = DatabaseListItem(
    scope: DatabaseScope.mysql,
    name: 'db_main',
    engine: 'mysql',
    source: 'local',
  );

  const detail = DatabaseDetailData(
    item: mysqlItem,
    baseInfo: DatabaseBaseInfo(containerName: 'mysql'),
  );

  test('DatabaseDetailProvider updateDescription triggers write and reload',
      () async {
    final service = _FakeDetailService(detail: detail);
    final provider = DatabaseDetailProvider(
      item: mysqlItem,
      service: service,
    );

    await provider.load();
    expect(service.loadDetailCallCount, 1);

    final ok = await provider.updateDescription('new description');

    expect(ok, isTrue);
    expect(provider.error, isNull);
    expect(service.updateDescriptionCallCount, 1);
    expect(service.lastDescription, 'new description');
    expect(service.loadDetailCallCount, 2);
    expect(provider.isSubmitting, isFalse);
  });

  test('DatabaseDetailProvider updateDescription handles write failures',
      () async {
    final service = _FakeDetailService(
      detail: detail,
      throwOnUpdateDescription: true,
    );
    final provider = DatabaseDetailProvider(
      item: mysqlItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.updateDescription('bad write');

    expect(ok, isFalse);
    expect(provider.error, contains('update failed'));
    expect(service.updateDescriptionCallCount, 1);
    expect(service.loadDetailCallCount, 1);
    expect(provider.isSubmitting, isFalse);
  });
}
