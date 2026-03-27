import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/pages/backup_account_form_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_account_form_provider.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/features/backups/services/backup_oauth_callback_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockBackupAccountService extends Mock implements BackupAccountService {}

class _MockBackupOauthCallbackService extends Mock
    implements BackupOauthCallbackService {}

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
    registerFallbackValue(const BackupAccountFormArgs());
    registerFallbackValue(const BackupAccountDraft(type: 'SFTP'));
  });

  testWidgets('BackupAccountFormPage renders sections', (tester) async {
    final service = _MockBackupAccountService();
    final callbackService = _MockBackupOauthCallbackService();
    final controller = StreamController<Uri>.broadcast();
    when(() => callbackService.start()).thenAnswer((_) async {});
    when(() => callbackService.callbacks).thenAnswer((_) => controller.stream);
    when(() => callbackService.consumeInitialUri()).thenReturn(null);
    when(() => callbackService.dispose()).thenAnswer((_) async {});
    when(() => service.initializeDraft(any()))
        .thenAnswer((_) async => const BackupAccountDraft(type: 'SFTP'));
    when(() => service.supportsOAuth(any())).thenReturn(false);
    when(() => service.creatableProviderTypes())
        .thenReturn(const <String>['SFTP', 'WebDAV']);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupAccountFormProvider>(
            create: (_) => BackupAccountFormProvider(
              service: service,
              callbackService: callbackService,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupAccountFormPage(args: BackupAccountFormArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);
    await controller.close();
  });

  testWidgets('BackupAccountFormPage does not initialize when no server is active',
      (tester) async {
    final service = _MockBackupAccountService();
    final callbackService = _MockBackupOauthCallbackService();
    final controller = StreamController<Uri>.broadcast();
    when(() => callbackService.start()).thenAnswer((_) async {});
    when(() => callbackService.callbacks).thenAnswer((_) => controller.stream);
    when(() => callbackService.consumeInitialUri()).thenReturn(null);
    when(() => callbackService.dispose()).thenAnswer((_) async {});
    when(() => service.creatableProviderTypes())
        .thenReturn(const <String>['SFTP', 'WebDAV']);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<BackupAccountFormProvider>(
            create: (_) => BackupAccountFormProvider(
              service: service,
              callbackService: callbackService,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BackupAccountFormPage(args: BackupAccountFormArgs()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.initializeDraft(any()));
    await controller.close();
  });
}
