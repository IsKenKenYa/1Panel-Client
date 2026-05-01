import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';

void main() {
  group('TerminalLaunchIntent', () {
    test('defaults to workbench when route args are empty', () {
      final intent = TerminalLaunchIntent.fromRouteArgs(null);
      expect(intent.kind, TerminalTargetKind.workbench);
      expect(intent.autoStart, isFalse);
    });

    test('parses container exec args', () {
      final intent = TerminalLaunchIntent.fromRouteArgs(<String, dynamic>{
        'type': 'container',
        'containerId': 'abc123',
        'containerName': 'redis-1',
        'command': '/bin/bash',
        'user': 'root',
      });

      expect(intent.kind, TerminalTargetKind.containerExec);
      expect(intent.containerId, 'abc123');
      expect(intent.containerName, 'redis-1');
      expect(intent.command, '/bin/bash');
      expect(intent.user, 'root');
      expect(
        intent.queryParameters(columns: 120, rows: 36),
        containsPair('source', 'container'),
      );
      expect(
        intent.queryParameters(columns: 120, rows: 36),
        containsPair('containerid', 'abc123'),
      );
    });

    test('parses saved host args', () {
      final intent = TerminalLaunchIntent.fromRouteArgs(<String, dynamic>{
        'type': 'host',
        'hostId': 42,
        'hostLabel': 'prod-web',
      });

      expect(intent.kind, TerminalTargetKind.savedHost);
      expect(intent.hostId, 42);
      expect(intent.hostLabel, 'prod-web');
      expect(
        intent.queryParameters(columns: 100, rows: 30),
        containsPair('id', '42'),
      );
    });
  });
}
