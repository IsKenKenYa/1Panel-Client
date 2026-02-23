import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanelapp_app/shared/widgets/log_viewer/log_viewer_controller.dart';

void main() {
  group('LogViewerController', () {
    late LogViewerController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = LogViewerController();
    });

    test('Initial state', () {
      expect(controller.logs, isEmpty);
      expect(controller.filteredLogs, isEmpty);
      expect(controller.settings.fontSize, 14.0);
      expect(controller.searchQuery, isEmpty);
      expect(controller.currentMatchIndex, -1);
    });

    test('setLogs parses logs correctly', () async {
      const rawLogs = '''
2023-01-01 12:00:00 [INFO] Info message
2023-01-01 12:00:01 [ERROR] Error message
2023-01-01 12:00:02 [WARN] Warning message
2023-01-01 12:00:03 [DEBUG] Debug message
Simple log line
''';
      await controller.setLogs(rawLogs);

      expect(controller.logs.length, 5);
      expect(controller.logs[0].level, LogLevel.info);
      expect(controller.logs[0].timestamp, DateTime(2023, 1, 1, 12, 0, 0));
      expect(controller.logs[1].level, LogLevel.error);
      expect(controller.logs[4].level, LogLevel.unknown);
    });

    test('setLogs calculates firstLogTimestamp', () async {
      const rawLogs = '''
Log line without timestamp
2023-01-01 12:00:00 [INFO] Info message
2023-01-01 12:00:01 [ERROR] Error message
''';
      await controller.setLogs(rawLogs);
      expect(controller.firstLogTimestamp, DateTime(2023, 1, 1, 12, 0, 0));
    });

    test('LogParser extracts timestampEndIndex', () async {
       var lines = await LogParser.parse('2023-01-01 12:00:00 [INFO] Message');
       expect(lines.first.timestampEndIndex, 19);
    });

    test('LogParser handles various formats', () async {
      // ISO 8601 with T and Z
      var lines = await LogParser.parse('2023-01-01T12:00:00Z [INFO] Message');
      expect(lines.first.timestamp, DateTime.utc(2023, 1, 1, 12, 0, 0));
      expect(lines.first.level, LogLevel.info);

      // Standard format
      lines = await LogParser.parse('2023-01-01 12:00:00 [INFO] Message');
      var line = lines.first;
      expect(line.level, LogLevel.info);
      expect(line.timestamp, DateTime(2023, 1, 1, 12, 0, 0));

      // With milliseconds
      lines = await LogParser.parse('2023-01-01 12:00:00.123 [ERROR] Message');
      line = lines.first;
      expect(line.level, LogLevel.error);
      expect(line.timestamp, DateTime(2023, 1, 1, 12, 0, 0, 123));

      // Fallback level detection
      lines = await LogParser.parse('Some random text containing ERROR');
      line = lines.first;
      expect(line.level, LogLevel.error);
      expect(line.timestamp, isNull);

      lines = await LogParser.parse('Some random text containing WARN');
      expect(lines.first.level, LogLevel.warn);

      lines = await LogParser.parse('Some random text containing INFO');
      expect(lines.first.level, LogLevel.info);
      
      lines = await LogParser.parse('Some random text containing DEBUG');
      expect(lines.first.level, LogLevel.debug);
    });

    test('search filters logs correctly', () async {
      const rawLogs = '''
Log line 1
Log line 2 matches
Log line 3
''';
      await controller.setLogs(rawLogs);
      controller.search('matches');

      expect(controller.filteredLogs.length, 3);
      expect(controller.filteredLogs[0].isMatch, false);
      expect(controller.filteredLogs[1].isMatch, true);
      expect(controller.filteredLogs[2].isMatch, false);
    });
    
    test('search is case insensitive', () async {
      const rawLogs = 'Log Line Matches';
      await controller.setLogs(rawLogs);
      controller.search('matches');
      
      expect(controller.filteredLogs[0].isMatch, true);
    });

    test('updateSettings updates settings', () {
      final newSettings = LogSettings(fontSize: 16.0, viewMode: LogViewMode.wrap);
      controller.updateSettings(newSettings);

      expect(controller.settings.fontSize, 16.0);
      expect(controller.settings.viewMode, LogViewMode.wrap);
    });
  });
}
