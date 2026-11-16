@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/services/browser_file_operations.dart';
import 'package:onepanel_client/core/services/logger/log_file_manager_service.dart';
import 'package:web/web.dart' as web;

void main() {
  test('Blob URL 保持文件字节和 MIME 类型，释放后无法读取', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final url = BrowserFileOperations.createUrl(bytes, mimeType: 'image/png');
    final response = await web.window.fetch(url.toJS).toDart;
    expect(response.headers.get('content-type'), 'image/png');
    final data = await response.arrayBuffer().toDart;
    expect(data.toDart.asUint8List(), bytes);
    BrowserFileOperations.revokeUrl(url);
    await expectLater(web.window.fetch(url.toJS).toDart, throwsA(anything));
  });

  test('浏览器日志保持有限数量并支持读取与清除', () async {
    final logs = LogFileManagerService();
    await logs.clearLogs();
    for (var i = 0; i < 2010; i++) {
      await logs.appendLine('INFO browser log $i');
    }
    final saved = await logs.readAllLogs();
    expect(saved.split('\n'), hasLength(2000));
    expect(saved, startsWith('INFO browser log 10\n'));
    expect(await logs.tailCurrentLog(1), 'INFO browser log 2009');
    await logs.clearLogs();
    expect(await logs.readAllLogs(), isEmpty);
  });
}
