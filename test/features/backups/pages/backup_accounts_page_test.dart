import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/features/backups/pages/backup_accounts_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockBackupAccountService extends Mock implements BackupAccountService {}

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
    registerFallbackValue(
      const BackupAccountInfo(name: 'fallback', type: 'S3'),
    );
  });

  testWidgets('BackupAccountsPage renders account card', (tester) async {
    final service = _MockBackupAccountService();
    when(() => service.searchAccounts(keyword: any(named: 'keyword'), type: any(named: 'type')))
        .thenAnswer(
      (_) async => const <BackupAccountInfo>[
        BackupAccountInfo(
          id: 1,
          name: 'backup-s3',
          type: 'S3',
          isPublic: false,
          bucket: 'bucket',
          backupPath: '/1panel',
        ),
      ],
    );
    when(() => service.isReadOnlyLocal(any())).thenReturn(false);
    when(() => service.endpointText(any())).thenReturn('s3.example.com');
    when(() => service.supportsRefreshToken(any())).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupAccountsProvider>(
            create: (_) => BackupAccountsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupAccountsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('backup-s3'), findsOneWidget);
  });

  testWidgets('BackupAccountsPage does not load when no server is active',
      (tester) async {
    final service = _MockBackupAccountService();
    when(() => service.isReadOnlyLocal(any())).thenReturn(false);
    when(() => service.endpointText(any())).thenReturn('');
    when(() => service.supportsRefreshToken(any())).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupAccountsProvider>(
            create: (_) => BackupAccountsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupAccountsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.searchAccounts(keyword: any(named: 'keyword'), type: any(named: 'type')));
  });
}
