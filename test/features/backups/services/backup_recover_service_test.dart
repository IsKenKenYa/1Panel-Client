import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/services/backup_recover_service.dart';

void main() {
  final service = BackupRecoverService();

  test('resolveSource maps required Week 5 record sources explicitly', () {
    final cases = <String,
        ({
      String category,
      String recordType,
      String requestType,
      String databaseType,
      bool supportsRecoverAction
    })>{
      'app': (
        category: 'app',
        recordType: 'app',
        requestType: 'app',
        databaseType: 'mysql',
        supportsRecoverAction: true,
      ),
      'website': (
        category: 'website',
        recordType: 'website',
        requestType: 'website',
        databaseType: 'mysql',
        supportsRecoverAction: true,
      ),
      'mysql': (
        category: 'database',
        recordType: 'mysql',
        requestType: 'mysql',
        databaseType: 'mysql',
        supportsRecoverAction: true,
      ),
      'postgresql': (
        category: 'database',
        recordType: 'postgresql',
        requestType: 'postgresql',
        databaseType: 'postgresql',
        supportsRecoverAction: true,
      ),
      'redis': (
        category: 'database',
        recordType: 'redis',
        requestType: 'redis',
        databaseType: 'redis',
        supportsRecoverAction: true,
      ),
      'directory': (
        category: 'other',
        recordType: 'directory',
        requestType: 'directory',
        databaseType: 'mysql',
        supportsRecoverAction: false,
      ),
      'snapshot': (
        category: 'other',
        recordType: 'snapshot',
        requestType: 'snapshot',
        databaseType: 'mysql',
        supportsRecoverAction: false,
      ),
      'log': (
        category: 'other',
        recordType: 'log',
        requestType: 'log',
        databaseType: 'mysql',
        supportsRecoverAction: false,
      ),
    };

    for (final entry in cases.entries) {
      final source = service.resolveSource(
        BackupRecoverArgs(
          type: entry.key,
          name: 'demo',
          detailName: 'detail',
        ),
      );

      expect(source.category, entry.value.category);
      expect(source.recordType, entry.value.recordType);
      expect(source.requestType, entry.value.requestType);
      expect(source.databaseType, entry.value.databaseType);
      expect(
        source.supportsRecoverAction,
        entry.value.supportsRecoverAction,
      );
      expect(source.name, 'demo');
      expect(source.detailName, 'detail');
    }
  });

  test('resolveSource preserves mysql-family raw request type', () {
    final source = service.resolveSource(
      const BackupRecoverArgs(
        type: 'mysql-cluster',
        name: 'db-main',
        detailName: 'cluster-a',
      ),
    );

    expect(source.category, 'database');
    expect(source.recordType, 'mysql-cluster');
    expect(source.requestType, 'mysql-cluster');
    expect(source.databaseType, 'mysql');
    expect(source.supportsRecoverAction, isTrue);
  });

  test('sourceForCategory keeps unsupported other fallback explicit', () {
    final source = service.sourceForCategory(
      'other',
      fallbackOtherType: 'snapshot',
    );

    expect(source.category, 'other');
    expect(source.recordType, 'snapshot');
    expect(source.requestType, 'snapshot');
    expect(source.supportsRecoverAction, isFalse);
  });

  test('buildRecoverRequest keeps the resolved request type', () {
    const record = BackupRecord(
      id: 1,
      downloadAccountID: 2,
      fileDir: '/data',
      fileName: 'dump.sql.gz',
      status: 'Success',
    );

    final request = service.buildRecoverRequest(
      record: record,
      type: 'postgresql',
      name: 'db-main',
      detailName: 'prod',
      secret: '',
      timeout: 3600,
    );

    expect(request.type, 'postgresql');
    expect(request.name, 'db-main');
    expect(request.detailName, 'prod');
    expect(request.file, '/data/dump.sql.gz');
    expect(request.downloadAccountID, 2);
    expect(request.timeout, 3600);
  });
}
