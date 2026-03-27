import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';

import '../core/test_config_manager.dart';

void main() {
  group('S2 Database integration', () {
    test(
        'database search executes against the configured server when integration is enabled',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.canRunIntegrationTests) {
        return;
      }

      final api = DatabaseV2Api(
        DioClient(
          baseUrl: TestEnvironment.baseUrl,
          apiKey: TestEnvironment.apiKey,
        ),
      );

      final response = await api.searchDatabases(
        const DatabaseSearch(
          page: 1,
          pageSize: 5,
          orderBy: 'createdAt',
          order: 'descending',
        ),
      );

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
    });

    test('database backup write flow is explicitly gated behind destructive mode',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.runIntegrationTests ||
          !TestEnvironment.runDestructiveTests) {
        return;
      }

      final client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      final api = BackupAccountV2Api(client);
      final response = await api.backupSystemData(
        const CommonBackup(
          type: 'mysql',
          name: 'mysql',
          detailName: 'app_db',
        ),
      );

      expect(response.statusCode, isNotNull);
    });
  });
}
