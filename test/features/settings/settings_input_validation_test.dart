import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/settings/monitor_settings_page.dart';
import 'package:onepanel_client/features/settings/widgets/system_settings_tiles.dart';

void main() {
  test('monitor interval accepts both upstream limits in seconds', () {
    expect(isValidMonitorInterval(null), isFalse);
    expect(isValidMonitorInterval(9), isFalse);
    expect(isValidMonitorInterval(10), isTrue);
    expect(isValidMonitorInterval(43200), isTrue);
    expect(isValidMonitorInterval(43201), isFalse);
  });

  test('export folder accepts one directory name or the download directory', () {
    for (final name in ['', 'KenPanel', '服务器导出']) {
      expect(isValidExportFolderName(name), isTrue, reason: name);
    }
    for (final name in ['.', '..', '../logs', r'logs\daily', 'aux.txt', 'a:b', 'logs.']) {
      expect(isValidExportFolderName(name), isFalse, reason: name);
    }
  });
}
