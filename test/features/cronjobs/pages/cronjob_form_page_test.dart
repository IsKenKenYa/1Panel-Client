import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_draft.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjob_form_page.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_form_provider.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_form_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockCronjobFormService extends Mock implements CronjobFormService {}

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
    registerFallbackValue(const CronjobFormArgs());
  });

  testWidgets('CronjobFormPage renders sections', (tester) async {
    final service = _MockCronjobFormService();
    when(() => service.loadDraft(any())).thenAnswer(
      (_) async => const CronjobFormDraft(primaryType: 'shell'),
    );
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => const <GroupInfo>[
        GroupInfo(id: 1, name: 'Default', type: 'cronjob', isDefault: true),
      ],
    );
    when(() => service.loadScriptOptions()).thenAnswer(
      (_) async => const <CronjobScriptOption>[
        CronjobScriptOption(id: 1, name: 'deploy'),
      ],
    );
    when(() => service.loadBackupOptions()).thenAnswer(
      (_) async => const <BackupOption>[
        BackupOption(id: 1, isPublic: false, name: 'local', type: 'LOCAL'),
      ],
    );
    when(() => service.loadInstalledApps())
        .thenAnswer((_) async => <AppInstallInfo>[]);
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseItems(any())).thenAnswer((_) async => const []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobFormProvider>(
            create: (_) => CronjobFormProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobFormPage(args: CronjobFormArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('CronjobFormPage does not initialize when no server is active',
      (tester) async {
    final service = _MockCronjobFormService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<CronjobFormProvider>(
            create: (_) => CronjobFormProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CronjobFormPage(args: CronjobFormArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.loadDraft(any()));
  });
}
