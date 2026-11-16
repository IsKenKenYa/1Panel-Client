@TestOn('vm')
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/server/server_connection_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment('PANEL_BASE_URL');
  const apiKey = String.fromEnvironment('PANEL_API_KEY');
  const enabled = baseUrl != '' && apiKey != '';

  group('真实面板 HMAC-SHA256', skip: !enabled, () {
    test('连接测试使用新签名读取系统信息', () async {
      final result = await ServerConnectionService().testConnection(
        serverUrl: baseUrl, apiKey: apiKey,
      );
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.osInfo, isNotEmpty);
    });

    test('共享 DioClient 完成数据流上传、下载与删除', () async {
      final client = DioClient(baseUrl: baseUrl, apiKey: apiKey);
      final api = FileV2Api(client);
      final directory = '/root/onepanel-hmac-test-${DateTime.now().microsecondsSinceEpoch}';
      await api.createFile(FileCreate(path: directory, isDir: true));
      try {
        final content = utf8.encode('1Panel Client HMAC-SHA256 真实文件验证\n');
        await api.uploadFile(directory, MultipartFile.fromStream(
          () => Stream.value(content), content.length, filename: 'hmac-transfer.txt',
        ));
        final response = await api.downloadFile('$directory/hmac-transfer.txt');
        expect(response.data, content);
      } finally {
        await api.deleteFiles(FileBatchDelete(paths: [directory], isDir: true));
        client.dio.close();
      }
    });
  });
}
