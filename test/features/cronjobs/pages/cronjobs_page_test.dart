import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjobs_page.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjobs_provider.dart';
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
  setUpAll(() {
    registerFallbackValue(const CronjobListQuery());
  });

  testWidgets('CronjobsPage renders cronjob card and actions', (tester) async {
    final service = _MockCronjobService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => const <GroupInfo>[
        GroupInfo(id: 1, name: 'Default', type: 'cronjob', isDefault: true),
      ],
    );
    when(() => service.searchCronjobs(any())).thenAnswer(
      (_) async => const PageResult<CronjobSummary>(
        items: <CronjobSummary>[
          CronjobSummary(
            id: 1,
            name: 'Daily Backup',
            type: 'shell',
            groupId: 1,
            groupBelong: 'Default',
            spec: '0 2 * * *',
            specCustom: false,
            status: 'Enable',
            lastRecordStatus: 'Success',
            lastRecordTime: '2026-03-27 02:00:00',
            retainCopies: 7,
            scriptMode: '',
            command: 'echo backup',
            executor: 'root',
            nextHandlePreview: '2026-03-28 02:00:00',
          ),
        ],
        total: 1,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobsProvider>(
            create: (_) => CronjobsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily Backup'), findsOneWidget);
    expect(find.text('Handle once'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
  });

  testWidgets('CronjobsPage does not load when no server is active',
      (tester) async {
    final service = _MockCronjobService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobsProvider>(
            create: (_) => CronjobsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(
        () => service.loadGroups(forceRefresh: any(named: 'forceRefresh')));
    verifyNever(() => service.searchCronjobs(any()));
  });
}
