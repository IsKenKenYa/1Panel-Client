import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/files_service.dart';

@GenerateMocks([FilesService])
import 'files_provider_test.mocks.dart';

void main() {
  late FilesProvider provider;
  late MockFilesService mockService;

  setUp(() {
    mockService = MockFilesService();
    provider = FilesProvider(service: mockService);
  });

  group('FilesProvider Tests', () {
    final testFiles = [
      FileInfo(
        name: 'folder1',
        path: '/folder1',
        isDir: true,
        size: 0,
        modifiedAt: DateTime(2023, 1, 1),
        mode: '0755',
        type: 'dir',
        user: 'root',
        group: 'root',
        permission: 'rwxr-xr-x',
      ),
      FileInfo(
        name: 'file1.txt',
        path: '/file1.txt',
        isDir: false,
        size: 1024,
        modifiedAt: DateTime(2023, 1, 1),
        mode: '0644',
        type: 'file',
        user: 'root',
        group: 'root',
        permission: 'rw-r--r--',
      ),
    ];

    test('loadFiles should update state with files', () async {
      // Arrange
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => testFiles);

      // Act
      await provider.loadFiles(path: '/');

      // Assert
      expect(provider.data.files, testFiles);
      expect(provider.data.isLoading, false);
      expect(provider.data.currentPath, '/');
      verify(mockService.getFiles(path: '/', search: null)).called(1);
    });

    test('initialize loads server and files before deferring favorites',
        () async {
      final server = ApiConfig(
        id: 'server-1',
        name: 'Demo',
        url: 'https://demo.test',
        apiKey: 'key',
      );
      when(mockService.getCurrentServer()).thenAnswer((_) async => server);
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => testFiles);
      when(mockService.searchFavoriteFiles(path: anyNamed('path')))
          .thenAnswer((_) async => const []);

      await provider.initialize();

      expect(provider.data.currentServer?.id, 'server-1');
      expect(provider.data.files, testFiles);
      expect(provider.data.isLoading, isFalse);
      verify(mockService.getCurrentServer()).called(1);
      verify(mockService.getFiles(path: '/', search: null)).called(1);
    });

    test('fetchFiles should return files without updating state', () async {
      // Arrange
      when(mockService.getFiles(path: anyNamed('path')))
          .thenAnswer((_) async => testFiles);

      // Act
      final result = await provider.fetchFiles('/test');

      // Assert
      expect(result, testFiles);
      // State should not change (assuming initial state is empty/default)
      expect(provider.data.files, isEmpty);
      verify(mockService.getFiles(path: '/test')).called(1);
    });

    test('createDirectory should call service and refresh', () async {
      // Arrange
      when(mockService.createDirectory(any)).thenAnswer((_) async {});
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => []);

      // Act
      await provider.createDirectory('new_folder');

      // Assert
      verify(mockService.createDirectory('/new_folder')).called(1);
      // Refresh calls loadFiles
      verify(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .called(1);
    });

    test('navigateTo should update path and load files', () async {
      // Arrange
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => []);

      // Act
      await provider.navigateTo('/new/path');

      // Assert
      expect(provider.data.currentPath, '/new/path');
      verify(mockService.getFiles(path: '/new/path', search: null)).called(1);
    });
  });
}
