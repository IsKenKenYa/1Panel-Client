import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/file_models.dart';

void main() {
  group('FileV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic> Function() responseBuilder;

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final payload = await utf8.decoder.bind(request).join();
        requestBody = payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('aligns /files/convert route and payload', () async {
      final api = FileV2Api(client);

      await api.convertFiles(
        const FileMediaConvertRequest(
          files: <FileMediaConvertItem>[
            FileMediaConvertItem(
              path: '/tmp',
              type: 'video',
              inputFile: 'demo.mp4',
              extension: '.mp4',
              outputFormat: 'mp3',
            ),
          ],
          outputPath: '/tmp/output',
          deleteSource: true,
          taskID: 'task-1',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/files/convert');
      expect(requestBody, <String, dynamic>{
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': '/tmp',
            'type': 'video',
            'inputFile': 'demo.mp4',
            'extension': '.mp4',
            'outputFormat': 'mp3',
          },
        ],
        'outputPath': '/tmp/output',
        'deleteSource': true,
        'taskID': 'task-1',
      });
    });

    test('aligns /files/remarks route and parses wrapped remarks map',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'remarks': <String, String>{
                '/tmp/demo.mp4': 'media source',
                '/tmp/output.mp3': 'converted',
              },
            },
          };

      final api = FileV2Api(client);
      final response = await api.batchGetFileRemarks(
        const FileRemarkBatch(
            paths: <String>['/tmp/demo.mp4', '/tmp/output.mp3']),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/files/remarks');
      expect(requestBody, <String, dynamic>{
        'paths': <String>['/tmp/demo.mp4', '/tmp/output.mp3'],
      });
      expect(response.data?.remarks['/tmp/demo.mp4'], 'media source');
      expect(response.data?.remarks['/tmp/output.mp3'], 'converted');
    });

    test('aligns /files/remark route and payload', () async {
      final api = FileV2Api(client);

      await api.setFileRemark(
        const FileRemarkUpdate(path: '/tmp/demo.mp4', remark: 'updated'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/files/remark');
      expect(requestBody, <String, dynamic>{
        'path': '/tmp/demo.mp4',
        'remark': 'updated',
      });
    });
  });
}
