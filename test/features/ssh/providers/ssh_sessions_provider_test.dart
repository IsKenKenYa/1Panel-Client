import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_sessions_provider.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class _MockSshService extends Mock implements SSHService {}

void main() {
  late _MockSshService service;
  late SshSessionsProvider provider;
  late StreamController<List<SshSessionInfo>> controller;

  setUpAll(() {
    registerFallbackValue(const SshSessionQuery());
  });

  setUp(() {
    controller = StreamController<List<SshSessionInfo>>.broadcast();
    service = _MockSshService();
    when(() => service.watchSessions()).thenAnswer((_) => controller.stream);
    when(() => service.connectSessions(any())).thenAnswer((_) async {});
    when(() => service.disconnectSession(any())).thenAnswer((_) async {});
    when(() => service.closeSessions()).thenAnswer((_) async {});
    provider = SshSessionsProvider(service: service);
  });

  tearDown(() async {
    await controller.close();
  });

  test('load binds websocket session stream', () async {
    await provider.load();
    controller.add(const <SshSessionInfo>[
      SshSessionInfo(
        username: 'root',
        pid: 1,
        terminal: 'pts/0',
        host: '1.1.1.1',
        loginTime: '2026-01-01 00:00:00',
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.items, hasLength(1));
  });

  test('applyFilters reconnects with new query', () async {
    await provider.applyFilters(const SshSessionQuery(loginUser: 'root'));

    verify(() =>
            service.connectSessions(const SshSessionQuery(loginUser: 'root')))
        .called(greaterThanOrEqualTo(1));
  });
}
