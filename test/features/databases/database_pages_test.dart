import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_detail_page.dart';
import 'package:onepanel_client/features/databases/databases_form_page.dart';
import 'package:onepanel_client/features/databases/databases_redis_page.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';
import 'package:onepanel_client/features/databases/pages/database_backup_page.dart';
import 'package:onepanel_client/features/databases/pages/database_users_page.dart';
import 'package:onepanel_client/features/databases/services/database_backup_service.dart';
import 'package:onepanel_client/features/databases/services/database_user_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart'
    as backup;
import 'package:onepanel_client/data/models/common_models.dart';

class _FakeDatabaseDetailService extends DatabasesService {
  _FakeDatabaseDetailService(this.detail);

  final DatabaseDetailData detail;

  @override
  Future<DatabaseDetailData> loadDetail(DatabaseListItem item) async => detail;
}

class _FakeDatabaseBackupPageService extends DatabaseBackupService {
  _FakeDatabaseBackupPageService(this.pageResult);

  final PageResult<backup.BackupRecord> pageResult;

  @override
  Future<PageResult<backup.BackupRecord>> loadRecords(
    DatabaseListItem item, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return pageResult;
  }
}

class _FakeDatabaseUserPageService extends DatabaseUserService {
  _FakeDatabaseUserPageService(this.context);

  final DatabaseUserContext context;

  @override
  Future<DatabaseUserContext> loadContext(DatabaseListItem item) async =>
      context;
}

class _FakeDatabaseRedisPageService extends DatabasesService {
  _FakeDatabaseRedisPageService(this.detail);

  final DatabaseDetailData detail;

  int updateRedisConfigCallCount = 0;
  int updateRedisPersistenceCallCount = 0;

  @override
  Future<DatabaseDetailData> loadDetail(DatabaseListItem item) async => detail;

  @override
  Future<void> updateRedisConfig({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    updateRedisConfigCallCount += 1;
  }

  @override
  Future<void> updateRedisPersistence({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    updateRedisPersistenceCallCount += 1;
  }
}

void main() {
  testWidgets('DatabaseDetailPage hides unsupported remote actions',
      (tester) async {
    const remoteItem = DatabaseListItem(
      scope: DatabaseScope.remote,
      name: 'remote-db',
      engine: 'mysql',
      source: 'remote',
      address: '10.0.0.1',
      username: 'admin',
    );

    final service = _FakeDatabaseDetailService(
      const DatabaseDetailData(
        item: remoteItem,
        baseInfo: DatabaseBaseInfo(containerName: 'remote'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseDetailPage(
          item: remoteItem,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change Password'), findsNothing);
    expect(find.text('Bind User'), findsNothing);
  });

  testWidgets('DatabaseFormPage excludes redis from creatable scopes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DatabaseFormPage(initialScope: DatabaseScope.redis),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('mysql'), findsWidgets);
    expect(find.text('redis'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<DatabaseScope>));
    await tester.pumpAndSettle();

    expect(find.text('mysql'), findsWidgets);
    expect(find.text('postgresql'), findsOneWidget);
    expect(find.text('remote'), findsOneWidget);
    expect(find.text('redis'), findsNothing);
  });

  testWidgets('DatabaseDetailPage shows management entries for mysql',
      (tester) async {
    const mysqlItem = DatabaseListItem(
      scope: DatabaseScope.mysql,
      name: 'app_db',
      engine: 'mysql-main',
      source: 'local',
    );

    final service = _FakeDatabaseDetailService(
      const DatabaseDetailData(item: mysqlItem),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseDetailPage(item: mysqlItem, service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
  });

  testWidgets('DatabaseBackupPage renders empty state', (tester) async {
    const mysqlItem = DatabaseListItem(
      scope: DatabaseScope.mysql,
      name: 'app_db',
      engine: 'mysql-main',
      source: 'local',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseBackupPage(
          item: mysqlItem,
          service: _FakeDatabaseBackupPageService(
            const PageResult(items: [], total: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('No backup records yet.'), findsOneWidget);
  });

  testWidgets('DatabaseUsersPage shows privilege card for postgresql',
      (tester) async {
    const pgItem = DatabaseListItem(
      scope: DatabaseScope.postgresql,
      name: 'app_db',
      engine: 'pg-main',
      source: 'local',
      username: 'db_user',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseUsersPage(
          item: pgItem,
          service: _FakeDatabaseUserPageService(
            const DatabaseUserContext(
              supportsBinding: true,
              supportsPrivileges: true,
              currentUsername: 'db_user',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Update Privileges'), findsWidgets);
  });

  testWidgets('DatabaseRedisPage save actions trigger write requests',
      (tester) async {
    const redisItem = DatabaseListItem(
      scope: DatabaseScope.redis,
      name: 'redis-main',
      engine: 'redis',
      source: 'local',
    );

    final service = _FakeDatabaseRedisPageService(
      const DatabaseDetailData(
        item: redisItem,
        redisConfig: {'timeout': '30', 'maxclients': '1000'},
        redisPersistence: {'appendonly': 'yes', 'save': '900 1'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DatabaseRedisPage(
          item: redisItem,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButtons = find.widgetWithText(FilledButton, 'Save');
    await tester.tap(saveButtons.first);
    await tester.pumpAndSettle();

    final secondSaveButton = saveButtons.last;
    await tester.ensureVisible(secondSaveButton);
    await tester.pumpAndSettle();
    await tester.tap(secondSaveButton);
    await tester.pumpAndSettle();

    expect(service.updateRedisConfigCallCount, 1);
    expect(service.updateRedisPersistenceCallCount, 1);
  });
}
