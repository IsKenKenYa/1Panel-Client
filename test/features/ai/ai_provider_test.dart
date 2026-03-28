import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/ai_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/ai/ai_repository.dart';

class MockAIRepository extends Mock implements AIRepository {}

void main() {
  group('AIProvider', () {
    late MockAIRepository repository;
    late AIProvider provider;

    setUp(() {
      repository = MockAIRepository();
      provider = AIProvider(repository: repository);
    });

    test('searchOllamaModels success updates model list', () async {
      when(
        () => repository.searchOllamaModels(
          page: 1,
          pageSize: 20,
          info: 'llama',
        ),
      ).thenAnswer(
        (_) async => PageResult<OllamaModel>(
          items: [
            OllamaModel(id: 1, name: 'llama3', size: '4.7GB'),
          ],
          total: 1,
        ),
      );

      final success = await provider.searchOllamaModels(info: 'llama');

      expect(success, isTrue);
      expect(provider.ollamaModelList, hasLength(1));
      expect(provider.ollamaModelList.first.name, 'llama3');
      expect(provider.errorMessage, isNull);
    });

    test('searchOllamaModels failure exposes error', () async {
      when(
        () => repository.searchOllamaModels(
          page: 1,
          pageSize: 20,
          info: null,
        ),
      ).thenThrow(Exception('network down'));

      final success = await provider.searchOllamaModels();

      expect(success, isFalse);
      expect(provider.errorMessage, contains('搜索Ollama模型失败'));
    });

    test('bindDomain success reloads current binding', () async {
      when(
        () => repository.bindDomain(
          appInstallID: 12,
          domain: 'ai.example.com',
          ipList: null,
          sslID: null,
          websiteID: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/ai/bind'),
        ),
      );

      when(
        () => repository.getBindDomain(appInstallID: 12),
      ).thenAnswer(
        (_) async => OllamaBindDomainRes(
          domain: 'ai.example.com',
          connUrl: 'https://ai.example.com',
          allowIPs: const ['10.0.0.1'],
        ),
      );

      final success = await provider.bindDomain(
        appInstallId: 12,
        domain: 'ai.example.com',
      );

      expect(success, isTrue);
      expect(provider.bindDomainInfo?.domain, 'ai.example.com');
      verify(() => repository.getBindDomain(appInstallID: 12)).called(1);
    });

    test('loadOllamaModel stores operation message', () async {
      when(
        () => repository.loadOllamaModel(name: 'qwen2', taskID: null),
      ).thenAnswer((_) async => 'model loaded');

      final success = await provider.loadOllamaModel(name: 'qwen2');

      expect(success, isTrue);
      expect(provider.lastOperationMessage, 'model loaded');
    });
  });
}
