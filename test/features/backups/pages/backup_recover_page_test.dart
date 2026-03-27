import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/pages/backup_recover_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_recover_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockBackupRecoverService extends Mock implements BackupRecoverService {}

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
  final mappingService = BackupRecoverService();
  const record = BackupRecord(
    id: 1,
    accountType: 'S3',
    accountName: 'bucket',
    downloadAccountID: 1,
    fileDir: '/data',
    fileName: 'dump.tar.gz',
    status: 'Success',
    createdAt: '2026-03-27',
  );

  const staleRecord = BackupRecord(
    id: 99,
    accountType: 'S3',
    accountName: 'bucket',
    downloadAccountID: 1,
    fileDir: '/data',
    fileName: 'stale.tar.gz',
    status: 'Success',
    createdAt: '2026-03-27',
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required BackupRecoverService service,
    required BackupRecoverArgs args,
    CurrentServerController? serverController,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: serverController ?? _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupRecoverProvider>(
            create: (_) => BackupRecoverProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: BackupRecoverPage(args: args),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() {
    registerFallbackValue(const BackupRecoverArgs());
  });

  _MockBackupRecoverService buildService() {
    final service = _MockBackupRecoverService();
    when(() => service.loadAppOptions())
        .thenAnswer((_) async => <AppInstallInfo>[]);
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseOptions(any())).thenAnswer(
      (_) async => const <DatabaseItemOption>[
        DatabaseItemOption(
          id: 1,
          from: 'local',
          database: 'mysql',
          name: 'prod',
        ),
      ],
    );
    when(() => service.resolveSource(any())).thenAnswer(
      (invocation) => mappingService.resolveSource(
        invocation.positionalArguments.first as BackupRecoverArgs?,
      ),
    );
    when(() => service.isRecoverSupportedType(any())).thenAnswer(
      (invocation) => mappingService.isRecoverSupportedType(
        invocation.positionalArguments.first as String,
      ),
    );
    when(
      () => service.sourceForCategory(
        any(),
        fallbackOtherType: any(named: 'fallbackOtherType'),
      ),
    ).thenAnswer(
      (invocation) => mappingService.sourceForCategory(
        invocation.positionalArguments.first as String,
        fallbackOtherType:
            invocation.namedArguments[#fallbackOtherType] as String?,
      ),
    );
    when(() => service.loadCandidateRecords(
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer((_) async => const <BackupRecord>[record]);
    return service;
  }

  testWidgets('BackupRecoverPage renders stepper', (tester) async {
    await pumpPage(
      tester,
      service: buildService(),
      args: const BackupRecoverArgs(),
    );

    expect(find.text('Resource'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets(
      'BackupRecoverPage maps mysql/postgresql/redis record context into database flow',
      (tester) async {
    for (final type in const <String>['mysql', 'postgresql', 'redis']) {
      final service = buildService();

      await pumpPage(
        tester,
        service: service,
        args: BackupRecoverArgs(
          type: type,
          name: 'db-main',
          detailName: 'prod',
          initialRecord: record,
        ),
      );

      expect(find.text('Database'), findsAtLeastNWidgets(1));
      expect(find.text('Database type'), findsOneWidget);
      expect(find.text('Start recover'), findsOneWidget);
    }
  });

  testWidgets('BackupRecoverPage does not initialize when no server is active',
      (tester) async {
    final service = buildService();

    await pumpPage(
      tester,
      service: service,
      args: const BackupRecoverArgs(),
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.loadAppOptions());
  });

  testWidgets('BackupRecoverPage renders unsupported type context',
      (tester) async {
    for (final type in const <String>['directory', 'snapshot', 'log']) {
      final service = buildService();

      await pumpPage(
        tester,
        service: service,
        args: BackupRecoverArgs(
          type: type,
          name: '$type-name',
          detailName: '$type-detail',
          initialRecord: record,
        ),
      );

      expect(find.text('Other'), findsOneWidget);
      expect(
        find.textContaining('direct recover is not available yet'),
        findsOneWidget,
      );
      expect(find.text('Start recover'), findsNothing);
    }
  });

  testWidgets(
      'BackupRecoverPage clears stale selectedRecord and returns to record step',
      (tester) async {
    final service = buildService();
    when(() => service.loadCandidateRecords(
          type: any(named: 'type'),
          name: any(named: 'name'),
          detailName: any(named: 'detailName'),
        )).thenAnswer((_) async => const <BackupRecord>[]);

    await pumpPage(
      tester,
      service: service,
      args: const BackupRecoverArgs(
        type: 'app',
        name: 'wordpress',
        detailName: 'WordPress',
        initialRecord: staleRecord,
      ),
    );

    expect(find.text('No candidate records'), findsOneWidget);
    expect(find.text('stale.tar.gz'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start recover'),
    );
    expect(button.onPressed, isNull);
  });
}
