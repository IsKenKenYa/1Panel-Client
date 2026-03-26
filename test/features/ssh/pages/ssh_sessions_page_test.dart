import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_sessions_page.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_sessions_provider.dart';
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
  late StreamController<List<SshSessionInfo>> controller;

  setUpAll(() {
    registerFallbackValue(const SshSessionQuery());
  });

  setUp(() {
    controller = StreamController<List<SshSessionInfo>>.broadcast();
  });

  tearDown(() async {
    await controller.close();
  });

  testWidgets('SshSessionsPage renders session item', (tester) async {
    final service = _MockSshService();
    when(() => service.watchSessions()).thenAnswer((_) => controller.stream);
    when(() => service.connectSessions(any())).thenAnswer((_) async {});
    when(() => service.closeSessions()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<SshSessionsProvider>(
            create: (_) => SshSessionsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshSessionsPage(),
        ),
      ),
    );
    controller.add(const <SshSessionInfo>[
      SshSessionInfo(
        username: 'root',
        pid: 1,
        terminal: 'pts/0',
        host: '1.1.1.1',
        loginTime: '2026-01-01 00:00:00',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('SshSessionsPage does not connect when no server is active',
      (tester) async {
    final service = _MockSshService();
    when(() => service.watchSessions()).thenAnswer((_) => controller.stream);
    when(() => service.closeSessions()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<SshSessionsProvider>(
            create: (_) => SshSessionsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SshSessionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(() => service.connectSessions(any()));
  });
}
