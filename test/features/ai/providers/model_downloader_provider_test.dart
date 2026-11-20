import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/model_downloader_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/ai/model_downloader_service.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';

class _MockModelDownloaderService extends Mock
    implements ModelDownloaderService {}

void main() {
  late _MockModelDownloaderService service;
  late ModelDownloaderProvider provider;

  setUpAll(() {
    registerFallbackValue(const FeaturedModelSearch());
    registerFallbackValue(const ModelSearch());
    registerFallbackValue(const ModelDownload(repoID: 'org/model'));
    registerFallbackValue(const LocalModelSearch());
    registerFallbackValue(const LocalModelDelete(name: 'model'));
    registerFallbackValue(const ModelDownloadTaskSearch());
    registerFallbackValue(const ModelDownloadTaskOperate(id: 1));
    registerFallbackValue(const OperateByID(id: 1));
    registerFallbackValue(const ModelDownloaderSetting(modelDir: '/models'));
  });

  setUp(() {
    service = _MockModelDownloaderService();
    provider = ModelDownloaderProvider(service: service);
  });

  tearDown(() {
    provider.dispose();
  });

  group('ModelDownloaderProvider', () {
    test('loadFeatured stores catalog and families', () async {
      when(() => service.searchFeatured(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            family: any(named: 'family'),
            info: any(named: 'info'),
          )).thenAnswer((_) async => const FeaturedModelPage(
            items: <FeaturedModel>[
              FeaturedModel(
                key: 'qwen',
                repoID: 'Qwen/Qwen3',
                family: 'Qwen',
                weightGB: 6.2,
              ),
            ],
            total: 1,
            families: <String>['Qwen', 'Llama'],
          ));

      await provider.loadFeatured();

      expect(provider.featured.items.length, 1);
      expect(provider.featured.families.length, 2);
      expect(provider.featuredError, isNull);
    });

    test('loadFeatured applies the family filter', () async {
      when(() => service.searchFeatured(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            family: any(named: 'family'),
            info: any(named: 'info'),
          )).thenAnswer((_) async => const FeaturedModelPage());

      await provider.loadFeatured(family: 'Qwen');

      expect(provider.featuredFamily, 'Qwen');
      verify(() => service.searchFeatured(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            family: 'Qwen',
            info: any(named: 'info'),
          )).called(1);
    });

    test('search uses Hugging Face when the source is hf', () async {
      when(() => service.searchHuggingFace(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            query: any(named: 'query'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PageResult<ModelItem>(
            items: <ModelItem>[
              ModelItem(repoID: 'org/model', sizeFormatted: '7B'),
            ],
            total: 1,
          ));

      await provider.search(source: 'hf', query: 'qwen');

      expect(provider.searchSource, 'hf');
      expect(provider.searchResults.length, 1);
      verifyNever(() => service.searchModelScope(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            query: any(named: 'query'),
            sort: any(named: 'sort'),
          ));
    });

    test('search uses ModelScope when the source is modelscope', () async {
      when(() => service.searchModelScope(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            query: any(named: 'query'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PageResult<ModelItem>(
            items: <ModelItem>[],
            total: 0,
          ));

      await provider.search(source: 'modelscope');

      expect(provider.searchSource, 'modelscope');
      verify(() => service.searchModelScope(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            query: any(named: 'query'),
            sort: any(named: 'sort'),
          )).called(1);
    });

    test('search records an error when the service throws', () async {
      when(() => service.searchHuggingFace(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            query: any(named: 'query'),
            sort: any(named: 'sort'),
          )).thenThrow(Exception('offline'));

      await provider.search(source: 'hf');

      expect(provider.searchResults, isEmpty);
      expect(provider.searchError, isNotNull);
    });

    test('downloadFeatured resolves the source-specific repo id', () async {
      when(() => service.downloadHuggingFace(
            repoID: any(named: 'repoID'),
            revision: any(named: 'revision'),
            downloadType: any(named: 'downloadType'),
          )).thenAnswer((_) async {});
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[],
            total: 0,
          ));

      const model = FeaturedModel(
        repoID: 'Qwen/Qwen3',
        sources: <String>['hf', 'modelscope'],
        sourceModelIds: <String, String>{'hf': 'Qwen/Qwen3-HF'},
      );

      await provider.downloadFeatured(model);

      verify(() => service.downloadHuggingFace(
            repoID: 'Qwen/Qwen3-HF',
            revision: any(named: 'revision'),
            downloadType: any(named: 'downloadType'),
          )).called(1);
    });

    test('downloadFeatured falls back to the model repo id', () async {
      when(() => service.downloadHuggingFace(
            repoID: any(named: 'repoID'),
            revision: any(named: 'revision'),
            downloadType: any(named: 'downloadType'),
          )).thenAnswer((_) async {});
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[],
            total: 0,
          ));

      const model = FeaturedModel(repoID: 'Qwen/Qwen3');

      await provider.downloadFeatured(model);

      verify(() => service.downloadHuggingFace(
            repoID: 'Qwen/Qwen3',
            revision: any(named: 'revision'),
            downloadType: any(named: 'downloadType'),
          )).called(1);
    });

    test('loadTasks stores items and tracks active downloads', () async {
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[
              ModelDownloadTaskItem(id: 1, status: 'running', progress: 0.4),
            ],
            total: 1,
          ));

      await provider.loadTasks();

      expect(provider.tasks.length, 1);
      expect(provider.hasActiveTasks, isTrue);
    });

    test('hasActiveTasks is false with completed tasks only', () async {
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[
              ModelDownloadTaskItem(id: 1, status: 'completed', progress: 1),
            ],
            total: 1,
          ));

      await provider.loadTasks();

      expect(provider.hasActiveTasks, isFalse);
    });

    test('cancelTask forwards the file flag and reloads tasks', () async {
      when(() => service.cancelTask(any(), withFile: any(named: 'withFile')))
          .thenAnswer((_) async {});
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[],
            total: 0,
          ));

      await provider.cancelTask(1, withFile: true);

      verify(() => service.cancelTask(1, withFile: true)).called(1);
    });

    test('deleteLocalModel forwards the file flag', () async {
      when(() => service.deleteLocalModel(
            name: any(named: 'name'),
            downloadType: any(named: 'downloadType'),
            withFile: any(named: 'withFile'),
          )).thenAnswer((_) async {});
      when(() => service.searchLocal(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            info: any(named: 'info'),
            downloadType: any(named: 'downloadType'),
          )).thenAnswer((_) async => const PageResult<LocalModelItem>(
            items: <LocalModelItem>[],
            total: 0,
          ));

      await provider.deleteLocalModel('qwen', withFile: false);

      verify(() => service.deleteLocalModel(
            name: 'qwen',
            downloadType: any(named: 'downloadType'),
            withFile: false,
          )).called(1);
    });

    test('loadSettings stores the downloader configuration', () async {
      when(() => service.getSettings()).thenAnswer(
        (_) async => const ModelDownloaderSetting(
          modelDir: '/opt/models',
          hfEndpoint: 'https://hf-mirror.com',
          featuredModelsSync: 'Enable',
        ),
      );

      await provider.loadSettings();

      expect(provider.settings.modelDir, '/opt/models');
      expect(provider.settings.hfEndpoint, 'https://hf-mirror.com');
      expect(provider.settingsError, isNull);
    });

    test('loadSettings records error when the endpoint is unavailable',
        () async {
      when(() => service.getSettings()).thenThrow(Exception('404'));

      await provider.loadSettings();

      expect(provider.settingsError, isNotNull);
    });

    test('onServerChanged resets service and reloads sections', () async {
      when(() => service.resetForServerChange()).thenReturn(null);
      when(() => service.searchFeatured(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            family: any(named: 'family'),
            info: any(named: 'info'),
          )).thenAnswer((_) async => const FeaturedModelPage());
      when(() => service.searchTasks(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            status: any(named: 'status'),
            includeLocal: any(named: 'includeLocal'),
          )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
            items: <ModelDownloadTaskItem>[],
            total: 0,
          ));
      when(() => service.searchLocal(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            info: any(named: 'info'),
            downloadType: any(named: 'downloadType'),
          )).thenAnswer((_) async => const PageResult<LocalModelItem>(
            items: <LocalModelItem>[],
            total: 0,
          ));

      await provider.onServerChanged();

      verify(() => service.resetForServerChange()).called(1);
      expect(provider.featured.items, isEmpty);
      expect(provider.tasks, isEmpty);
    });
  });
}
