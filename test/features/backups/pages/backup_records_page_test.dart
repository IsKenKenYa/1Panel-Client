import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/pages/backup_records_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_records_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_record_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockBackupRecordService extends Mock implements BackupRecordService {}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;
}

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  final item = BackupRecordListItem(
    record: const BackupRecord(
      id: 1,
      accountType: 'S3',
      accountName: 'bucket',
      downloadAccountID: 1,
      fileDir: '/data',
      fileName: 'dump.tar.gz',
      status: 'Success',
      createdAt: '2026-03-27',
    ),
    size: 100,
  );

  setUpAll(() {
    registerFallbackValue(item.record);
  });

  testWidgets('BackupRecordsPage renders record item', (tester) async {
    final service = _MockBackupRecordService();
    when(() => service.loadRecords(
          args: any(named: 'args'),
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer((_) async => <BackupRecordListItem>[item]);
    when(() => service.downloadRecord(any()))
        .thenAnswer((_) async => throw UnimplementedError());
    when(() => service.deleteRecord(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupRecordsProvider>(
            create: (_) => BackupRecordsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupRecordsPage(args: BackupRecordsArgs(type: 'app')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('dump.tar.gz'), findsOneWidget);
  });

  testWidgets('BackupRecordsPage does not load when no server is active',
      (tester) async {
    final service = _MockBackupRecordService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupRecordsProvider>(
            create: (_) => BackupRecordsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupRecordsPage(args: BackupRecordsArgs(type: 'app')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.loadRecords(
          args: any(named: 'args'),
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        ));
  });
}
