import 'dart:io';

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

    test('uploadFiles should use locked target path', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('files_upload_test');
      final tempFile = File('${tempDir.path}/demo.txt');
      await tempFile.writeAsString('demo');

      when(mockService.uploadFile(any, any)).thenAnswer((_) async {});

      await provider.uploadFiles(
        [tempFile.path],
        targetPath: '/locked/path',
      );

      verify(mockService.uploadFile('/locked/path', any)).called(1);

      await tempDir.delete(recursive: true);
    });

    test('onServerChangedWithIds should restore remembered path', () async {
      when(mockService.getCurrentServer()).thenAnswer((_) async => null);
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => const <FileInfo>[]);

      await provider.navigateTo('/var/www');
      provider.onServerChangedWithIds(
        previousServerId: 'server-a',
        nextServerId: 'server-b',
      );
      await Future<void>.delayed(Duration.zero);

      await provider.navigateTo('/opt/apps');
      provider.onServerChangedWithIds(
        previousServerId: 'server-b',
        nextServerId: 'server-a',
      );

      expect(provider.data.currentPath, '/var/www');
    });

    test('loadFileRemarks should return mapped remarks', () async {
      when(mockService.getFileRemarks(any))
          .thenAnswer((_) async => {'/file1.txt': 'demo remark'});

      final result = await provider.loadFileRemarks(['/file1.txt']);

      expect(result['/file1.txt'], 'demo remark');
      verify(mockService.getFileRemarks(['/file1.txt'])).called(1);
    });

    test('updateFileRemark should save and refresh current path', () async {
      when(mockService.setFileRemark(any, any)).thenAnswer((_) async {});
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => const <FileInfo>[]);

      await provider.updateFileRemark('/file1.txt', 'new remark');

      verify(mockService.setFileRemark('/file1.txt', 'new remark')).called(1);
      verify(mockService.getFiles(path: '/', search: null)).called(1);
    });

    test('convertFile should call service with normalized request', () async {
      when(
        mockService.convertFiles(
          files: anyNamed('files'),
          outputPath: anyNamed('outputPath'),
          deleteSource: anyNamed('deleteSource'),
          taskId: anyNamed('taskId'),
        ),
      ).thenAnswer((_) async {});
      when(mockService.getFiles(
              path: anyNamed('path'), search: anyNamed('search')))
          .thenAnswer((_) async => const <FileInfo>[]);

      await provider.convertFile(
        testFiles[1],
        outputFormat: 'mp3',
        outputPath: '/tmp',
      );

      final captured = verify(
        mockService.convertFiles(
          files: captureAnyNamed('files'),
          outputPath: captureAnyNamed('outputPath'),
          deleteSource: captureAnyNamed('deleteSource'),
          taskId: captureAnyNamed('taskId'),
        ),
      ).captured;

      final requestFiles = captured[0] as List<FileMediaConvertItem>;
      expect(requestFiles, hasLength(1));
      expect(requestFiles.single.path, '/');
      expect(requestFiles.single.inputFile, 'file1.txt');
      expect(requestFiles.single.extension, '.txt');
      expect(requestFiles.single.outputFormat, 'mp3');
      expect(captured[1], '/tmp');
      expect(captured[2], false);
      expect((captured[3] as String).startsWith('file-convert-'), isTrue);
      verify(mockService.getFiles(path: '/', search: null)).called(1);
    });
  });
}
