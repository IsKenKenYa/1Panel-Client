import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_settings_page.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_settings_provider.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockSshService extends Mock implements SSHService {}

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

  @override
  String? get currentServerId => _config.id;
}

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  const info = SshInfo(
    autoStart: true,
    isExist: true,
    isActive: true,
    message: 'running',
    port: '22',
    listenAddress: '0.0.0.0',
    passwordAuthentication: 'yes',
    pubkeyAuthentication: 'yes',
    permitRootLogin: 'yes',
    useDNS: 'no',
    currentUser: 'root',
  );

  testWidgets('SshSettingsPage renders sections', (tester) async {
    final service = _MockSshService();
    when(() => service.loadInfo()).thenAnswer((_) async => info);
    when(() => service.loadRawConfig()).thenAnswer((_) async => 'config');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<SshSettingsProvider>(
            create: (_) => SshSettingsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
  });

  testWidgets('SshSettingsPage does not load when no server is active',
      (tester) async {
    final service = _MockSshService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<SshSettingsProvider>(
            create: (_) => SshSettingsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.loadInfo());
  });
}
