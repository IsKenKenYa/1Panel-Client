import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/website_template_models.dart';

void main() {
  group('WebsiteV2Api template alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late String rawRequestBody;
    late Map<String, dynamic> Function(HttpRequest request) responseBuilder;

    Map<String, dynamic> templateJson() => <String, dynamic>{
          'id': 3,
          'name': 'nginx-basic',
          'type': 'single',
          'content': 'server {}',
          'filePath': '/templates/nginx.zip',
          'remark': 'demo',
          'variables': '[]',
          'createdAt': '2026-11-12 10:00:00',
          'updatedAt': '2026-11-12 11:00:00',
        };

    Map<String, dynamic> outputJson() => <String, dynamic>{
          'id': 8,
          'name': 'prod-conf',
          'templateID': 3,
          'templateName': 'nginx-basic',
          'templateType': 'single',
          'outputPath': '/etc/nginx/conf.d/prod.conf',
          'variableValues': '{"port":"8080"}',
          'createdAt': '2026-11-12 10:00:00',
          'updatedAt': '2026-11-12 11:00:00',
        };

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      rawRequestBody = '';
      responseBuilder =
          (_) => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final payload = await utf8.decoder.bind(request).join();
        rawRequestBody = payload;
        final isMultipart = request.headers.contentType?.primaryType ==
                'multipart' &&
            request.headers.contentType?.subType == 'form-data';
        requestBody = payload.isEmpty || isMultipart
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder(request)));
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

    test('aligns template search and parses page result', () async {
      responseBuilder = (request) {
        if (request.uri.path == '/api/v2/websites/templates/search') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'total': 1,
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  ...templateJson(),
                  'content': 'server {{port}}',
                  'variables': '[{"key":"port"}]',
                },
              ],
            },
          };
        }
        return <String, dynamic>{'code': 200, 'data': null};
      };

      final api = WebsiteV2Api(client);
      final result = await api.searchWebsiteTemplates(
        const WebsiteTemplateSearch(page: 1, pageSize: 10, name: 'nginx'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/websites/templates/search');
      expect(requestBody, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'name': 'nginx',
      });
      expect(result.total, 1);
      expect(result.items.single.name, 'nginx-basic');
      expect(result.items.single.variables, '[{"key":"port"}]');
    });

    test('aligns template create, update, get and delete routes', () async {
      responseBuilder = (request) {
        if (request.uri.path == '/api/v2/websites/templates/get') {
          return <String, dynamic>{'code': 200, 'data': templateJson()};
        }
        return <String, dynamic>{'code': 200, 'data': null};
      };
      final api = WebsiteV2Api(client);

      await api.createWebsiteTemplate(
        const WebsiteTemplateCreate(
          name: 'nginx-basic',
          type: 'single',
          content: 'server {}',
          variables: '[]',
          remark: 'demo',
        ),
      );
      expect(requestPath, '/api/v2/websites/templates');
      expect(requestBody, <String, dynamic>{
        'name': 'nginx-basic',
        'type': 'single',
        'content': 'server {}',
        'variables': '[]',
        'remark': 'demo',
      });

      await api.updateWebsiteTemplate(
        const WebsiteTemplateUpdate(
          id: 3,
          name: 'nginx-basic',
          type: 'multi',
          filePath: '/templates/new.zip',
        ),
      );
      expect(requestPath, '/api/v2/websites/templates/update');
      expect(requestBody, <String, dynamic>{
        'id': 3,
        'name': 'nginx-basic',
        'type': 'multi',
        'filePath': '/templates/new.zip',
      });

      final detail = await api.getWebsiteTemplate(
        const WebsiteTemplateIdReq(id: 3),
      );
      expect(requestPath, '/api/v2/websites/templates/get');
      expect(requestBody, <String, dynamic>{'id': 3});
      expect(detail.data?.id, 3);
      expect(detail.data?.name, 'nginx-basic');

      await api.deleteWebsiteTemplate(
        const WebsiteTemplateIdReq(id: 3),
      );
      expect(requestPath, '/api/v2/websites/templates/del');
      expect(requestBody, <String, dynamic>{'id': 3});
    });

    test('aligns template upload and preview routes', () async {
      responseBuilder = (request) {
        if (request.uri.path == '/api/v2/websites/templates/preview') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'html': '<h1>preview</h1>'},
          };
        }
        return <String, dynamic>{
          'code': 200,
          'data': <String, dynamic>{
            'filePath': '/templates/uploaded.zip',
            'variables': <String>['port'],
          },
        };
      };
      final api = WebsiteV2Api(client);

      final upload = await api.uploadWebsiteTemplateZip(
        MultipartFile.fromString('zip-bytes', filename: 'template.zip'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/websites/templates/upload');
      expect(rawRequestBody, contains('name="file"'));
      expect(rawRequestBody, contains('filename="template.zip"'));
      expect(upload.data?['filePath'], '/templates/uploaded.zip');

      final preview = await api.previewWebsiteTemplate(
        const WebsitePreviewReq(
          templateID: 3,
          variableValues: <String, String>{'port': '8080'},
        ),
      );
      expect(requestPath, '/api/v2/websites/templates/preview');
      expect(requestBody, <String, dynamic>{
        'templateID': 3,
        'variableValues': <String, String>{'port': '8080'},
      });
      expect(preview.data?.html, '<h1>preview</h1>');
    });

    test('aligns template output routes', () async {
      responseBuilder = (request) {
        if (request.uri.path == '/api/v2/websites/templates/outputs/search') {
          return <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'total': 1,
              'items': <Map<String, dynamic>>[outputJson()],
            },
          };
        }
        if (request.uri.path == '/api/v2/websites/templates/outputs/get') {
          return <String, dynamic>{'code': 200, 'data': outputJson()};
        }
        return <String, dynamic>{'code': 200, 'data': null};
      };
      final api = WebsiteV2Api(client);

      await api.createWebsiteTemplateOutput(
        const WebsiteTemplateOutputCreate(
          name: 'prod-conf',
          templateID: 3,
          variableValues: <String, String>{'port': '8080'},
        ),
      );
      expect(requestPath, '/api/v2/websites/templates/outputs');
      expect(requestBody, <String, dynamic>{
        'name': 'prod-conf',
        'templateID': 3,
        'variableValues': <String, String>{'port': '8080'},
      });

      final list = await api.searchWebsiteTemplateOutputs(
        const WebsiteTemplateOutputSearch(page: 1, pageSize: 10, templateID: 3),
      );
      expect(requestPath, '/api/v2/websites/templates/outputs/search');
      expect(requestBody, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'templateID': 3,
      });
      expect(list.items.single.outputPath, '/etc/nginx/conf.d/prod.conf');

      final detail = await api.getWebsiteTemplateOutput(
        const WebsiteTemplateIdReq(id: 8),
      );
      expect(requestPath, '/api/v2/websites/templates/outputs/get');
      expect(detail.data?.id, 8);

      await api.deleteWebsiteTemplateOutput(
        const WebsiteTemplateIdReq(id: 8),
      );
      expect(requestPath, '/api/v2/websites/templates/outputs/del');
      expect(requestBody, <String, dynamic>{'id': 8});
    });
  });
}
