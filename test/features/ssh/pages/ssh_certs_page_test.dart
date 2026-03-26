import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_certs_page.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_certs_provider.dart';
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
}

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  testWidgets('SshCertsPage renders cert card', (tester) async {
    final service = _MockSshService();
    when(() => service.searchCerts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer(
      (_) async => const PageResult<SshCertInfo>(
        items: <SshCertInfo>[
          SshCertInfo(
            id: 1,
            createdAt: null,
            name: 'default',
            encryptionMode: 'ed25519',
            passPhrase: '',
            publicKey: '',
            privateKey: '',
            description: '',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.syncCerts()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<SshCertsProvider>(
            create: (_) => SshCertsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshCertsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('default'), findsOneWidget);
  });

  testWidgets('SshCertsPage does not load when no server is active',
      (tester) async {
    final service = _MockSshService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<SshCertsProvider>(
            create: (_) => SshCertsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshCertsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.searchCerts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ));
  });
}
