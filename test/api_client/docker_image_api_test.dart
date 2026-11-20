import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/api/v2/docker_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';

import 'compose_api_test.mocks.dart';

@GenerateMocks([DioClient])
void main() {
  late DockerV2Api api;
  late MockDioClient mockClient;

  setUp(() {
    mockClient = MockDioClient();
    api = DockerV2Api(mockClient);
  });

  RequestOptions _opts(String path) => RequestOptions(path: path);

  Response<Map<String, dynamic>> _successResponse(
    Map<String, dynamic> data, {
    String path = '/test',
  }) {
    return Response(
      data: data,
      statusCode: 200,
      requestOptions: _opts(path),
    );
  }

  group('DockerV2Api - Images', () {
    group('listImages', () {
      test('returns list of DockerImage from wrapped response', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successResponse({
              'data': [
                {
                  'id': 'sha256:abc123',
                  'tags': ['nginx:latest'],
                  'size': 1024000,
                  'created': '2024-01-01',
                },
                {
                  'id': 'sha256:def456',
                  'tags': ['redis:7'],
                  'size': 512000,
                  'created': '2024-01-02',
                },
              ],
            }, path: '/containers/image/all'));

        final response = await api.listImages();
        expect(response.data, isA<List<DockerImage>>());
        expect(response.data!.length, 2);
        expect(response.data!.first.id, 'sha256:abc123');
        expect(response.data!.first.tags, ['nginx:latest']);
        expect(response.data!.first.size, 1024000);
        expect(response.data!.last.tags, ['redis:7']);
      });

      test('returns list from direct List response', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: [
                {
                  'id': 'sha256:abc123',
                  'tags': ['nginx:latest'],
                  'size': 1024000,
                  'created': '2024-01-01',
                },
              ],
              statusCode: 200,
              requestOptions: _opts('/containers/image/all'),
            ));

        final response = await api.listImages();
        expect(response.data, isA<List<DockerImage>>());
        expect(response.data!.length, 1);
      });

      test('returns empty list for unrecognized response format', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successResponse(
              {'unexpected': 'format'},
              path: '/containers/image/all',
            ));

        final response = await api.listImages();
        expect(response.data, isEmpty);
      });
    });

    group('pullImage', () {
      test('sends correct request body', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/pull'),
            ));

        final request = ImagePull(
          image: 'nginx',
          tag: 'latest',
        );
        await api.pullImage(request);

        final captured = verify(mockClient.post<void>(
          any,
          data: captureAnyNamed('data'),
        )).captured;
        final body = captured.single as Map<String, dynamic>;
        expect(body['imageName'], <String>['nginx:latest']);
        expect(body['taskID'], isA<String>());
      });
    });

    group('buildImage', () {
      test('returns build output string', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successResponse({
              'data': 'build-task-id-123',
            }, path: '/containers/image/build'));

        final request = ImageBuild(
          contextDir: '/tmp',
          dockerfile: 'Dockerfile',
          tags: ['my-image:v1.0'],
        );
        final response = await api.buildImage(request);
        expect(response.data, 'build-task-id-123');
      });

      test('returns empty string when data is null', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successResponse(
              {},
              path: '/containers/image/build',
            ));

        final request = ImageBuild(
          contextDir: '/tmp',
          dockerfile: 'Dockerfile',
          tags: ['my-image:v1.0'],
        );
        final response = await api.buildImage(request);
        expect(response.data, '');
      });
    });

    group('loadImage', () {
      test('sends load request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/load'),
            ));

        final request = ImageLoad(filePath: '/tmp/image.tar');
        final response = await api.loadImage(request);
        expect(response.statusCode, 200);
      });
    });

    group('saveImage', () {
      test('sends save request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/save'),
            ));

        final request = ImageSave(
          images: ['nginx:latest'],
          filePath: '/tmp/nginx.tar',
        );
        final response = await api.saveImage(request);
        expect(response.statusCode, 200);
      });
    });

    group('tagImage', () {
      test('sends tag request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/tag'),
            ));

        final request = ImageTag(
          sourceImage: 'nginx:latest',
          targetImage: 'my-registry/nginx',
          tag: 'v1',
        );
        final response = await api.tagImage(request);
        expect(response.statusCode, 200);
      });
    });

    group('pushImage', () {
      test('sends push request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/push'),
            ));

        final request = ImagePush(image: 'my-registry/nginx', tag: 'v1');
        final response = await api.pushImage(request);
        expect(response.statusCode, 200);
      });
    });

    group('searchImages', () {
      test('returns PageResult with image data', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successResponse({
              'data': {
                'items': [
                  {
                    'name': 'nginx',
                    'description': 'Official nginx image',
                    'star_count': 10000,
                  },
                ],
                'total': 1,
                'page': 1,
                'pageSize': 10,
              },
            }, path: '/containers/image/search'));

        final request = SearchWithPage(info: 'nginx', page: 1, pageSize: 10);
        final response = await api.searchImages(request);
        expect(response.data, isA<PageResult<Map<String, dynamic>>>());
        expect(response.data!.items.length, 1);
        expect(response.data!.items.first['name'], 'nginx');
        expect(response.data!.total, 1);
      });

      test('handles empty search results', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successResponse({
              'data': {
                'items': [],
                'total': 0,
              },
            }, path: '/containers/image/search'));

        final request = SearchWithPage(info: 'nonexistent');
        final response = await api.searchImages(request);
        expect(response.data!.items, isEmpty);
        expect(response.data!.total, 0);
      });
    });

    group('removeImage', () {
      test('sends remove request with image id and force flag', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/remove'),
            ));

        await api.removeImage('sha256:abc123', force: true);

        verify(mockClient.post<void>(
          any,
          data: {
            'names': ['sha256:abc123'],
            'force': true,
          },
        )).called(1);
      });

      test('defaults force to false', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/containers/image/remove'),
            ));

        await api.removeImage('sha256:abc123');

        verify(mockClient.post<void>(
          any,
          data: {
            'names': ['sha256:abc123'],
            'force': false,
          },
        )).called(1);
      });
    });
  });
}
