import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';
import 'package:onepanel_client/features/terminal/providers/terminal_workbench_provider.dart';
import 'package:onepanel_client/features/terminal/services/terminal_transport.dart';
import 'package:onepanel_client/features/terminal/services/terminal_workbench_service.dart';
import 'package:onepanel_client/features/terminal/terminal_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeTerminalTransport implements TerminalTransport {
  final StreamController<TerminalTransportEvent> _controller =
      StreamController<TerminalTransportEvent>.broadcast();

  @override
  Stream<TerminalTransportEvent> get events => _controller.stream;

  @override
  Future<void> connect() async {
    _controller.add(const TerminalStatusEvent('connected'));
    _controller.add(const TerminalOutputEvent('hello\r\n'));
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> heartbeat() async {}

  @override
  Future<void> resize({required int columns, required int rows}) async {}

  @override
  Future<void> sendInput(String data) async {}
}

class _FakeTerminalWorkbenchService extends TerminalWorkbenchService {
  _FakeTerminalWorkbenchService();

  final StreamController<List<SshSessionInfo>> sessionsController =
      StreamController<List<SshSessionInfo>>.broadcast();

  @override
  Future<TerminalInfo?> loadTerminalSettings() async => const TerminalInfo(
        fontSize: '14',
        lineHeight: '1.2',
      );

  @override
  Future<SshLocalConnectionInfo> loadLocalConnection() async =>
      const SshLocalConnectionInfo(
        addr: '127.0.0.1',
        port: 22,
        user: 'root',
        localSSHConnShow: 'Disable',
      );

  @override
  Future<List<HostTreeNode>> loadHostTree() async => const <HostTreeNode>[
        HostTreeNode(
          id: 1,
          label: 'Default',
          children: <HostTreeChild>[
            HostTreeChild(id: 2, label: 'demo-host'),
          ],
        ),
      ];

  @override
  Future<List<CommandTree>> loadQuickCommands() async => const <CommandTree>[
        CommandTree(
          label: 'Default',
          children: <CommandTree>[
            CommandTree(label: 'List', value: 'ls -la'),
          ],
        ),
      ];

  @override
  Stream<List<SshSessionInfo>> watchActiveSshSessions() =>
      sessionsController.stream;

  @override
  Future<void> connectActiveSshSessions(SshSessionQuery query) async {
    sessionsController.add(const <SshSessionInfo>[
      SshSessionInfo(
        username: 'root',
        pid: 1,
        terminal: 'pts/0',
        host: '127.0.0.1',
        loginTime: '2026-04-01 10:00',
      ),
    ]);
  }

  @override
  Future<void> disconnectActiveSshSession(int pid) async {}

  @override
  Future<void> closeActiveSshSessions() async {
    await sessionsController.close();
  }

  @override
  Future<_FakeTerminalTransport> createTransport({
    required TerminalLaunchIntent intent,
    required int columns,
    required int rows,
  }) async {
    return _FakeTerminalTransport();
  }
}

void main() {
  testWidgets('mobile terminal workbench renders session and active SSH list',
      (tester) async {
    final service = _FakeTerminalWorkbenchService();
    final provider = TerminalWorkbenchProvider(service: service);

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: TerminalPage(
          provider: provider,
          launchIntentOverride: const TerminalLaunchIntent.workbench(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Terminal Sessions'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('SSH Sessions'), findsOneWidget);
    expect(find.text('root'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Terminal Settings'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.pump();
  });

  testWidgets('opening local session twice reuses existing session', (tester) async {
    final service = _FakeTerminalWorkbenchService();
    final provider = TerminalWorkbenchProvider(service: service);

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: TerminalPage(
          provider: provider,
          launchIntentOverride: const TerminalLaunchIntent.workbench(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final localButton = find.widgetWithText(FilledButton, 'Local');
    await tester.tap(localButton);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(localButton);
    await tester.pumpAndSettle();

    expect(find.text('Local'), findsAtLeastNWidgets(1));
    expect(provider.sessions.length, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.pump();
  });
}
