import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_logs_page.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_logs_provider.dart';
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
  setUpAll(() {
    registerFallbackValue(const SshLogSearchRequest());
  });

  testWidgets('SshLogsPage renders log item', (tester) async {
    final service = _MockSshService();
    when(() => service.searchLogs(any())).thenAnswer(
      (_) async => const PageResult<SshLogEntry>(
        items: <SshLogEntry>[
          SshLogEntry(
            date: null,
            area: 'CN',
            user: 'root',
            authMode: 'password',
            address: '1.1.1.1',
            port: '22',
            status: 'Success',
            message: 'ok',
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
          ChangeNotifierProvider<SshLogsProvider>(
            create: (_) => SshLogsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshLogsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1.1.1.1:22'), findsOneWidget);
  });

  testWidgets('SshLogsPage does not load when no server is active',
      (tester) async {
    final service = _MockSshService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<SshLogsProvider>(
            create: (_) => SshLogsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshLogsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.searchLogs(any()));
  });
}
