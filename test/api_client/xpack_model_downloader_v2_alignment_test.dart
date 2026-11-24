import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/xpack_model_downloader_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/model_downloader_models.dart';

void main() {
  group('XpackModelDownloaderV2Api alignment', () {
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

    test('aligns featured/search route and page parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'key': 'qwen3',
                  'repoID': 'Qwen/Qwen3-8B',
                  'family': 'qwen3',
                  'architecture': 'Dense',
                  'backboneParams': '8B',
                  'activeParams': '8B',
                  'engram': '',
                  'weightGB': 16.2,
                  'sources': <String>['modelScope', 'hf'],
                  'sourceModelIds': <String, String>{
                    'modelScope': 'Qwen/Qwen3-8B-ms',
                    'hf': 'Qwen/Qwen3-8B',
                  },
                  'description': <String, String>{
                    'en': 'Qwen3 8B dense model',
                    'zh': 'Qwen3 8B 稠密模型',
                  },
                  'sort': 1,
                },
              ],
              'total': 1,
              'families': <String>['qwen3', 'llama'],
            },
          };

      final api = XpackModelDownloaderV2Api(client);
      final response = await api.searchFeaturedModels(
        const FeaturedModelSearch(page: 1, pageSize: 20, family: 'qwen3'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/xpack/model/downloader/featured/search');
      expect(requestBody?['family'], 'qwen3');
      expect(response.data?.items.single.repoID, 'Qwen/Qwen3-8B');
      expect(response.data?.families, contains('llama'));
    });

    test('aligns featured/sync/status route and payload', () async {
      final api = XpackModelDownloaderV2Api(client);
      await api.updateFeaturedSyncStatus(
        const ModelDownloaderSyncSetting(value: 'Enable'),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/featured/sync/status');
      expect(requestBody?['value'], 'Enable');
    });

    test('aligns hf/search route and page parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'repoID': 'Qwen/Qwen3-8B',
                  'name': 'Qwen3-8B',
                  'downloads': 12000,
                  'likes': 486,
                  'size': 16106127360,
                  'sizeFormatted': '16.2 GB',
                },
              ],
              'total': 1,
            },
          };

      final api = XpackModelDownloaderV2Api(client);
      final response = await api.searchHuggingFaceModels(
        const ModelSearch(page: 1, pageSize: 20, query: 'qwen'),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/hf/search');
      expect(requestBody?['query'], 'qwen');
      expect(response.data?.items.single.downloads, 12000);
    });

    test('aligns hf/info route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'repoID': 'Qwen/Qwen3-8B',
              'name': 'Qwen3-8B',
              'downloads': 12000,
              'likes': 486,
              'size': 16106127360,
              'sizeFormatted': '16.2 GB',
              'modelCard': '# Qwen3-8B\n\nQwen3 dense 8B model card.',
              'files': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'model.safetensors',
                  'size': 16106127360,
                  'sizeFormatted': '16.2 GB',
                },
              ],
            },
          };

      final api = XpackModelDownloaderV2Api(client);
      final response = await api.getHuggingFaceModelInfo(
        const ModelInfoReq(repoID: 'Qwen/Qwen3-8B'),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/hf/info');
      expect(requestBody?['repoID'], 'Qwen/Qwen3-8B');
      expect(response.data?.files.single.name, 'model.safetensors');
    });

    test('aligns modelscope/download route and payload', () async {
      final api = XpackModelDownloaderV2Api(client);
      await api.downloadModelScopeModel(
        const ModelDownload(repoID: 'qwen/qwen3-8b', downloadType: 'all'),
      );

      expect(
        requestPath,
        '/api/v2/xpack/model/downloader/modelscope/download',
      );
      expect(requestBody?['repoID'], 'qwen/qwen3-8b');
      expect(requestBody?['downloadType'], 'all');
    });

    test('aligns local/search route and page parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'Qwen3-8B',
                  'repoID': 'Qwen/Qwen3-8B',
                  'revision': 'main',
                  'downloadType': 'all',
                  'source': 'hf',
                  'path': '/opt/models/Qwen3-8B',
                  'size': 16106127360,
                  'sizeFormatted': '16.2 GB',
                  'createdAt': '2026-05-12T08:31:07+08:00',
                },
              ],
              'total': 1,
            },
          };

      final api = XpackModelDownloaderV2Api(client);
      final response = await api.searchLocalModels(
        const LocalModelSearch(page: 1, pageSize: 20),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/local/search');
      expect(response.data?.items.single.source, 'hf');
    });

    test('aligns local/delete route and payload', () async {
      final api = XpackModelDownloaderV2Api(client);
      await api.deleteLocalModel(
        const LocalModelDelete(name: 'Qwen3-8B', withFile: true),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/local/delete');
      expect(requestBody?['name'], 'Qwen3-8B');
      expect(requestBody?['withFile'], isTrue);
    });

    test('aligns tasks/search route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 4,
                  'modelName': 'Qwen3-8B',
                  'repoID': 'Qwen/Qwen3-8B',
                  'revision': 'main',
                  'downloadType': 'all',
                  'source': 'hf',
                  'status': 'downloading',
                  'progress': 42.5,
                  'downloadedSize': 6845104128,
                  'totalSize': 16106127360,
                  'targetDir': '/opt/models/Qwen3-8B',
                  'errorMessage': null,
                  'createdAt': '2026-05-12T08:20:03+08:00',
                  'startedAt': '2026-05-12T08:31:07+08:00',
                  'completedAt': null,
                  'canCancel': true,
                  'canRetry': false,
                  'canRemoveRecord': false,
                  'localModel': null,
                },
              ],
              'total': 1,
            },
          };

      final api = XpackModelDownloaderV2Api(client);
      final response = await api.searchDownloadTasks(
        const ModelDownloadTaskSearch(page: 1, pageSize: 20),
      );

      expect(requestPath, '/api/v2/xpack/model/downloader/tasks/search');
      expect(response.data?.items.single.progress, 42.5);
      expect(response.data?.items.single.canCancel, isTrue);
    });

    test('aligns tasks/cancel and tasks/retry routes', () async {
      final api = XpackModelDownloaderV2Api(client);
      await api.cancelDownloadTask(const ModelDownloadTaskOperate(id: 4));
      expect(requestPath, '/api/v2/xpack/model/downloader/tasks/cancel');
      expect(requestBody?['id'], 4);

      await api.retryDownloadTask(const OperateByID(id: 4));
      expect(requestPath, '/api/v2/xpack/model/downloader/tasks/retry');
      expect(requestBody?['id'], 4);
    });
  });
}
