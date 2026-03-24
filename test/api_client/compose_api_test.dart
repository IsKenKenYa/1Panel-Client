import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/api/v2/compose_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';

import 'compose_api_test.mocks.dart';

@GenerateMocks([DioClient])
void main() {
  late ComposeV2Api api;
  late MockDioClient mockClient;

  setUp(() {
    mockClient = MockDioClient();
    api = ComposeV2Api(mockClient);
  });

  group('ComposeV2Api', () {
    test('listComposes returns PageResult when items is a List', () async {
      final jsonResponse = {
        "items": [
          {
            "id": "1",
            "name": "test-compose",
            "path": "/opt/1panel/apps/test",
            "status": "running"
          }
        ],
        "total": 1,
        "page": 1,
        "pageSize": 10
      };

      when(mockClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));

      final response = await api.listComposes();
      expect(response.data, isA<PageResult<ComposeProject>>());
      expect(response.data!.items.length, 1);
      expect(response.data!.items.first.name, 'test-compose');
    });

    test('listComposes handles Map items by converting values to List (if supported) or empty', () async {
      // This simulates the condition where items is a Map
      final jsonResponse = {
        "items": {
           "1": { "id": "1", "name": "test-map" } 
        }, 
        "total": 1
      };

      when(mockClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));

      final response = await api.listComposes();
      // Current implementation returns empty list for Map. 
      // If we want to support Map, we should update PageResult.
      // For now, verify it doesn't crash.
      expect(response.data!.items, isEmpty); 
    });
    
    test('listComposes handles null items gracefully', () async {
      final jsonResponse = {
        "items": null,
        "total": 0
      };

      when(mockClient.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: jsonResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));

      final response = await api.listComposes();
      expect(response.data!.items, isEmpty);
    });
  });
}
