import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';

class _FakeDetailService extends DatabasesService {
  _FakeDetailService({
    required this.detail,
    this.throwOnUpdateDescription = false,
    this.throwOnChangePassword = false,
    this.throwOnBindUser = false,
    this.throwOnRedisConfig = false,
    this.throwOnRedisPersistence = false,
  });

  final DatabaseDetailData detail;
  final bool throwOnUpdateDescription;
  final bool throwOnChangePassword;
  final bool throwOnBindUser;
  final bool throwOnRedisConfig;
  final bool throwOnRedisPersistence;

  int loadDetailCallCount = 0;
  int updateDescriptionCallCount = 0;
  int changePasswordCallCount = 0;
  int bindUserCallCount = 0;
  int updateRedisConfigCallCount = 0;
  int updateRedisPersistenceCallCount = 0;
  String? lastDescription;
  String? lastPassword;
  String? lastUsername;
  Map<String, dynamic>? lastRedisConfigPayload;
  Map<String, dynamic>? lastRedisPersistencePayload;

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

  @override
  Future<void> changePassword(DatabaseListItem item, String password) async {
    changePasswordCallCount += 1;
    lastPassword = password;
    if (throwOnChangePassword) {
      throw Exception('password failed');
    }
  }

  @override
  Future<void> bindUser(
    DatabaseListItem item, {
    required String username,
    required String password,
  }) async {
    bindUserCallCount += 1;
    lastUsername = username;
    lastPassword = password;
    if (throwOnBindUser) {
      throw Exception('bind failed');
    }
  }

  @override
  Future<void> updateRedisConfig({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    updateRedisConfigCallCount += 1;
    lastRedisConfigPayload = payload;
    if (throwOnRedisConfig) {
      throw Exception('redis config failed');
    }
  }

  @override
  Future<void> updateRedisPersistence({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    updateRedisPersistenceCallCount += 1;
    lastRedisPersistencePayload = payload;
    if (throwOnRedisPersistence) {
      throw Exception('redis persistence failed');
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

  const pgItem = DatabaseListItem(
    scope: DatabaseScope.postgresql,
    name: 'pg_main',
    engine: 'postgresql',
    source: 'local',
  );

  const redisItem = DatabaseListItem(
    scope: DatabaseScope.redis,
    name: 'redis_main',
    engine: 'redis',
    source: 'local',
  );

  const detail = DatabaseDetailData(
    item: mysqlItem,
    baseInfo: DatabaseBaseInfo(containerName: 'mysql'),
  );

  const pgDetail = DatabaseDetailData(
    item: pgItem,
    baseInfo: DatabaseBaseInfo(containerName: 'postgresql'),
  );

  const redisDetail = DatabaseDetailData(
    item: redisItem,
    baseInfo: DatabaseBaseInfo(containerName: 'redis'),
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

  test('DatabaseDetailProvider changePassword triggers write and reload',
      () async {
    final service = _FakeDetailService(detail: pgDetail);
    final provider = DatabaseDetailProvider(
      item: pgItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.changePassword('new-pass');

    expect(ok, isTrue);
    expect(service.changePasswordCallCount, 1);
    expect(service.lastPassword, 'new-pass');
    expect(service.loadDetailCallCount, 2);
  });

  test('DatabaseDetailProvider changePassword handles write failures',
      () async {
    final service = _FakeDetailService(
      detail: pgDetail,
      throwOnChangePassword: true,
    );
    final provider = DatabaseDetailProvider(
      item: pgItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.changePassword('bad-pass');

    expect(ok, isFalse);
    expect(service.changePasswordCallCount, 1);
    expect(provider.error, contains('password failed'));
  });

  test('DatabaseDetailProvider bindUser handles write failures', () async {
    final service = _FakeDetailService(
      detail: pgDetail,
      throwOnBindUser: true,
    );
    final provider = DatabaseDetailProvider(
      item: pgItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.bindUser(
      username: 'db_user',
      password: 'secret',
    );

    expect(ok, isFalse);
    expect(service.bindUserCallCount, 1);
    expect(provider.error, contains('bind failed'));
  });

  test('DatabaseDetailProvider redis writes trigger reload', () async {
    final service = _FakeDetailService(detail: redisDetail);
    final provider = DatabaseDetailProvider(
      item: redisItem,
      service: service,
    );

    await provider.load();
    final configOk = await provider.updateRedisConfig({
      'timeout': '60',
      'maxclients': '1024',
    });
    final persistenceOk = await provider.updateRedisPersistence({
      'appendonly': 'yes',
      'save': '900 1',
    });

    expect(configOk, isTrue);
    expect(persistenceOk, isTrue);
    expect(service.updateRedisConfigCallCount, 1);
    expect(service.updateRedisPersistenceCallCount, 1);
    expect(service.loadDetailCallCount, 3);
    expect(service.lastRedisConfigPayload?['timeout'], '60');
    expect(service.lastRedisPersistencePayload?['appendonly'], 'yes');
  });

  test('DatabaseDetailProvider updateRedisConfig handles write failures',
      () async {
    final service = _FakeDetailService(
      detail: redisDetail,
      throwOnRedisConfig: true,
    );
    final provider = DatabaseDetailProvider(
      item: redisItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.updateRedisConfig({'timeout': '10'});

    expect(ok, isFalse);
    expect(service.updateRedisConfigCallCount, 1);
    expect(provider.error, contains('redis config failed'));
  });

  test('DatabaseDetailProvider updateRedisPersistence handles write failures',
      () async {
    final service = _FakeDetailService(
      detail: redisDetail,
      throwOnRedisPersistence: true,
    );
    final provider = DatabaseDetailProvider(
      item: redisItem,
      service: service,
    );

    await provider.load();
    final ok = await provider.updateRedisPersistence({'appendonly': 'no'});

    expect(ok, isFalse);
    expect(service.updateRedisPersistenceCallCount, 1);
    expect(provider.error, contains('redis persistence failed'));
  });
}
