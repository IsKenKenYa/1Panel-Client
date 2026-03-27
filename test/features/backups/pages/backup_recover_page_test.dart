import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/app_models.dart';
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
  testWidgets('BackupRecoverPage renders stepper', (tester) async {
    final service = _MockBackupRecoverService();
    when(() => service.loadAppOptions()).thenAnswer(
      (_) async => <AppInstallInfo>[
        AppInstallInfo(id: 1, name: 'WordPress', appKey: 'wordpress'),
      ],
    );
    when(() => service.loadWebsiteOptions())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => service.loadDatabaseOptions(any())).thenAnswer(
      (_) async => const <DatabaseItemOption>[
        DatabaseItemOption(id: 1, from: 'local', database: 'mysql', name: 'db1'),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupRecoverProvider>(
            create: (_) => BackupRecoverProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupRecoverPage(args: BackupRecoverArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resource'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
  });

  testWidgets('BackupRecoverPage does not initialize when no server is active',
      (tester) async {
    final service = _MockBackupRecoverService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupRecoverProvider>(
            create: (_) => BackupRecoverProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupRecoverPage(args: BackupRecoverArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.loadAppOptions());
  });
}
