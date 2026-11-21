@TestOn('browser')
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/container_log_stream_v2.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/server/server_connection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment('PANEL_BASE_URL');
  const apiKey = String.fromEnvironment('PANEL_API_KEY');
  const enabled = baseUrl != '' && apiKey != '';
  const logContainer = String.fromEnvironment('PANEL_LOG_CONTAINER');

  group('真实浏览器与 1Panel', skip: !enabled, () {
    test('CORS 预检通过后完成真实面板连接', () async {
      final result = await ServerConnectionService().testConnection(
        serverUrl: baseUrl,
        apiKey: apiKey,
      );
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.responseTime, isNotNull);
    });

    test('容器跟随日志在连接打开期间返回第一段文本', () async {
      final client = DioClient(baseUrl: baseUrl, apiKey: apiKey);
      addTearDown(() => client.dio.close(force: true));
      final logs = ContainerLogStreamV2Api(client).streamContainerLogs(
        container: logContainer,
        follow: true,
        tail: '10',
      );
      expect(await logs.timeout(const Duration(seconds: 15)).first, isNotEmpty);
    }, skip: logContainer.isEmpty);

    test('Multipart 数据流上传内容可以原样下载', () async {
      final api = FileV2Api(DioClient(baseUrl: baseUrl, apiKey: apiKey));
      final directory =
          '/root/onepanel-web-test-${DateTime.now().microsecondsSinceEpoch}';
      await api.createFile(FileCreate(path: directory, isDir: true));
      try {
        final content = utf8.encode('浏览器文件往返验证\n1Panel Client Web\n');
        await api.uploadFile(
          directory,
          MultipartFile.fromStream(() => Stream.value(content), content.length,
              filename: 'browser-transfer.txt'),
        );
        final response = await api.downloadFile('$directory/browser-transfer.txt');
        expect(response.data, content);
      } finally {
        await api.deleteFiles(FileBatchDelete(paths: [directory], isDir: true));
      }
    });
  });
}
