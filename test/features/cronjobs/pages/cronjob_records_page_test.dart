import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_records_args.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjob_records_page.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_records_provider.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockCronjobService extends Mock implements CronjobService {}

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
  const args = CronjobRecordsArgs(
    cronjobId: 1,
    name: 'Daily Backup',
    status: 'Enable',
  );

  setUpAll(() {
    registerFallbackValue(const CronjobRecordQuery(cronjobId: 1));
    registerFallbackValue(const CronjobRecordCleanRequest(cronjobId: 1));
  });

  testWidgets('CronjobRecordsPage renders record item', (tester) async {
    final service = _MockCronjobService();
    when(() => service.searchRecords(any())).thenAnswer(
      (_) async => const PageResult<CronjobRecordInfo>(
        items: <CronjobRecordInfo>[
          CronjobRecordInfo(
            id: 11,
            taskId: 'task-1',
            startTime: '2026-03-27 02:00:00',
            status: 'Success',
            message: 'done',
            targetPath: '/backup',
            interval: 1200,
            file: 'backup.log',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.loadRecordLog(any()))
        .thenAnswer((_) async => 'record log');
    when(() => service.cleanRecords(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobRecordsProvider>(
            create: (_) => CronjobRecordsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobRecordsPage(args: args),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-03-27 02:00:00'), findsOneWidget);
    expect(find.textContaining('done'), findsOneWidget);
  });

  testWidgets('CronjobRecordsPage does not load when no server is active',
      (tester) async {
    final service = _MockCronjobService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobRecordsProvider>(
            create: (_) => CronjobRecordsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobRecordsPage(args: args),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.searchRecords(any()));
  });
}
