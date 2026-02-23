import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/shared/widgets/log_viewer/log_viewer_controller.dart';

void main() {
  group('LogViewerController', () {
    late LogViewerController controller;

    setUp(() {
      controller = LogViewerController();
    });

    test('Initial state', () {
      expect(controller.logs, isEmpty);
      expect(controller.filteredLogs, isEmpty);
      expect(controller.settings.fontSize, 14.0);
      expect(controller.searchQuery, isEmpty);
      expect(controller.currentMatchIndex, -1);
    });

    test('setLogs parses logs correctly', () {
      const rawLogs = '''
2023-01-01 12:00:00 [INFO] Info message
2023-01-01 12:00:01 [ERROR] Error message
2023-01-01 12:00:02 [WARN] Warning message
2023-01-01 12:00:03 [DEBUG] Debug message
Simple log line
''';
      controller.setLogs(rawLogs);

      expect(controller.logs.length, 5);
      expect(controller.logs[0].level, LogLevel.info);
      expect(controller.logs[0].timestamp, DateTime(2023, 1, 1, 12, 0, 0));
      expect(controller.logs[1].level, LogLevel.error);
      expect(controller.logs[4].level, LogLevel.unknown);
    });

    test('parseLogLine handles various formats', () {
      // Standard format
      var line = controller.parseLogLine('2023-01-01 12:00:00 [INFO] Message');
      expect(line.level, LogLevel.info);
      expect(line.timestamp, DateTime(2023, 1, 1, 12, 0, 0));

      // With milliseconds
      line = controller.parseLogLine('2023-01-01 12:00:00.123 [ERROR] Message');
      expect(line.level, LogLevel.error);
      expect(line.timestamp, DateTime(2023, 1, 1, 12, 0, 0, 123));

      // Fallback level detection
      line = controller.parseLogLine('Some random text containing ERROR');
      expect(line.level, LogLevel.error);
      expect(line.timestamp, isNull);

      line = controller.parseLogLine('Some random text containing WARN');
      expect(line.level, LogLevel.warn);

      line = controller.parseLogLine('Some random text containing INFO');
      expect(line.level, LogLevel.info);
      
      line = controller.parseLogLine('Some random text containing DEBUG');
      expect(line.level, LogLevel.debug);
    });

    test('search filters logs correctly', () {
      const rawLogs = '''
Log line 1
Log line 2 matches
Log line 3
''';
      controller.setLogs(rawLogs);
      controller.search('matches');

      expect(controller.filteredLogs.length, 3);
      expect(controller.filteredLogs[0].isMatch, false);
      expect(controller.filteredLogs[1].isMatch, true);
      expect(controller.filteredLogs[2].isMatch, false);
    });
    
    test('search is case insensitive', () {
      const rawLogs = 'Log Line Matches';
      controller.setLogs(rawLogs);
      controller.search('matches');
      
      expect(controller.filteredLogs[0].isMatch, true);
    });

    test('updateSettings updates settings', () {
      final newSettings = LogSettings(fontSize: 16.0, isWrap: true);
      controller.updateSettings(newSettings);

      expect(controller.settings.fontSize, 16.0);
      expect(controller.settings.isWrap, true);
    });
  });
}
