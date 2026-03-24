import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/models/files_data.dart';
import 'package:onepanel_client/features/files/models/wget_download_status.dart';

void main() {
  group('FilesData Tests', () {
    test('creates with default values', () {
      const data = FilesData();
      
      expect(data.files, isEmpty);
      expect(data.currentPath, equals('/'));
      expect(data.pathHistory, equals(['/']));
      expect(data.isLoading, isFalse);
      expect(data.error, isNull);
      expect(data.selectedFiles, isEmpty);
      expect(data.sortBy, isNull);
      expect(data.sortOrder, isNull);
      expect(data.searchQuery, isNull);
      expect(data.currentServer, isNull);
      expect(data.mountInfo, isNull);
      expect(data.recycleBinStatus, isNull);
      expect(data.favorites, isEmpty);
      expect(data.favoritePaths, isEmpty);
      expect(data.wgetStatus, isNull);
      expect(data.isDownloading, isFalse);
      expect(data.downloadProgress, equals(0.0));
      expect(data.downloadingFileName, isNull);
    });

    test('creates with custom values', () {
      final files = [
        FileInfo(name: 'test.txt', path: '/test.txt', type: 'file', size: 100),
      ];
      final selectedFiles = {'/test.txt'};
      final favoritePaths = {'/test.txt'};
      final server = ApiConfig(
        id: 'test',
        name: 'Test Server',
        url: 'https://test.com',
        apiKey: 'key',
      );

      final data = FilesData(
        files: files,
        currentPath: '/home',
        pathHistory: ['/', '/home'],
        isLoading: true,
        error: 'Test error',
        selectedFiles: selectedFiles,
        sortBy: 'name',
        sortOrder: 'asc',
        searchQuery: 'test',
        currentServer: server,
        favorites: files,
        favoritePaths: favoritePaths,
        isDownloading: true,
        downloadProgress: 0.5,
        downloadingFileName: 'test.txt',
      );

      expect(data.files, equals(files));
      expect(data.currentPath, equals('/home'));
      expect(data.pathHistory, equals(['/', '/home']));
      expect(data.isLoading, isTrue);
      expect(data.error, equals('Test error'));
      expect(data.selectedFiles, equals(selectedFiles));
      expect(data.sortBy, equals('name'));
      expect(data.sortOrder, equals('asc'));
      expect(data.searchQuery, equals('test'));
      expect(data.currentServer, equals(server));
      expect(data.favorites, equals(files));
      expect(data.favoritePaths, equals(favoritePaths));
      expect(data.isDownloading, isTrue);
      expect(data.downloadProgress, equals(0.5));
      expect(data.downloadingFileName, equals('test.txt'));
    });

    test('copyWith creates new instance with updated values', () {
      const original = FilesData(
        currentPath: '/home',
        isLoading: true,
      );

      final updated = original.copyWith(
        currentPath: '/home/user',
        isLoading: false,
        error: 'New error',
      );

      expect(updated.currentPath, equals('/home/user'));
      expect(updated.isLoading, isFalse);
      expect(updated.error, equals('New error'));
      expect(original.currentPath, equals('/home')); // Original unchanged
      expect(original.isLoading, isTrue);
    });

    test('copyWith preserves original values when not specified', () {
      const original = FilesData(
        currentPath: '/home',
        isLoading: true,
        sortBy: 'name',
      );

      final updated = original.copyWith(isLoading: false);

      expect(updated.currentPath, equals('/home'));
      expect(updated.isLoading, isFalse);
      expect(updated.sortBy, equals('name'));
    });

    test('copyWith can set error to null', () {
      const original = FilesData(error: 'Test error');

      final updated = original.copyWith(error: null);

      expect(updated.error, isNull);
    });

    test('hasSelection returns correct value', () {
      const dataWithSelection = FilesData(
        selectedFiles: {'/test.txt'},
      );
      const dataWithoutSelection = FilesData();

      expect(dataWithSelection.hasSelection, isTrue);
      expect(dataWithoutSelection.hasSelection, isFalse);
    });

    test('selectionCount returns correct count', () {
      const dataWithTwo = FilesData(
        selectedFiles: {'/test1.txt', '/test2.txt'},
      );
      const dataWithNone = FilesData();

      expect(dataWithTwo.selectionCount, equals(2));
      expect(dataWithNone.selectionCount, equals(0));
    });

    test('isSelected returns correct value', () {
      const data = FilesData(
        selectedFiles: {'/test.txt'},
      );

      expect(data.isSelected('/test.txt'), isTrue);
      expect(data.isSelected('/other.txt'), isFalse);
    });

    test('isSearching returns correct value', () {
      const searching = FilesData(searchQuery: 'test');
      const notSearching = FilesData(searchQuery: null);
      const emptySearch = FilesData(searchQuery: '');

      expect(searching.isSearching, isTrue);
      expect(notSearching.isSearching, isFalse);
      expect(emptySearch.isSearching, isFalse);
    });

    test('hasServer returns correct value', () {
      final server = ApiConfig(
        id: 'test',
        name: 'Test',
        url: 'https://test.com',
        apiKey: 'key',
      );
      final dataWithServer = FilesData(currentServer: server);
      const dataWithoutServer = FilesData();

      expect(dataWithServer.hasServer, isTrue);
      expect(dataWithoutServer.hasServer, isFalse);
    });

    test('isFavorite returns correct value', () {
      const data = FilesData(
        favoritePaths: {'/test.txt'},
      );

      expect(data.isFavorite('/test.txt'), isTrue);
      expect(data.isFavorite('/other.txt'), isFalse);
    });

    test('copyWith updates selectedFiles correctly', () {
      const original = FilesData(
        selectedFiles: {'/test1.txt'},
      );

      final updated = original.copyWith(
        selectedFiles: {'/test1.txt', '/test2.txt'},
      );

      expect(updated.selectedFiles.length, equals(2));
      expect(updated.selectedFiles.contains('/test1.txt'), isTrue);
      expect(updated.selectedFiles.contains('/test2.txt'), isTrue);
    });

    test('copyWith updates pathHistory correctly', () {
      const original = FilesData(
        pathHistory: ['/', '/home'],
      );

      final updated = original.copyWith(
        pathHistory: ['/', '/home', '/home/user'],
      );

      expect(updated.pathHistory.length, equals(3));
      expect(updated.pathHistory.last, equals('/home/user'));
    });

    test('copyWith updates files correctly', () {
      final newFiles = [
        FileInfo(name: 'new.txt', path: '/new.txt', type: 'file', size: 200),
      ];

      final updated = const FilesData().copyWith(files: newFiles);

      expect(updated.files.length, equals(1));
      expect(updated.files.first.name, equals('new.txt'));
    });

    test('copyWith updates wgetStatus correctly', () {
      const newStatus = WgetDownloadStatus(
        state: WgetDownloadState.success,
        message: 'Download complete',
        filePath: '/downloaded.txt',
      );

      final updated = const FilesData().copyWith(wgetStatus: newStatus);

      expect(updated.wgetStatus?.state, equals(WgetDownloadState.success));
      expect(updated.wgetStatus?.message, equals('Download complete'));
      expect(updated.wgetStatus?.filePath, equals('/downloaded.txt'));
    });
  });

  group('WgetDownloadStatus Tests', () {
    test('creates with default values', () {
      const status = WgetDownloadStatus();

      expect(status.state, equals(WgetDownloadState.idle));
      expect(status.message, isNull);
      expect(status.filePath, isNull);
      expect(status.downloadedSize, isNull);
    });

    test('creates with custom values', () {
      const status = WgetDownloadStatus(
        state: WgetDownloadState.downloading,
        message: 'Downloading...',
        filePath: '/test.txt',
        downloadedSize: 1024,
      );

      expect(status.state, equals(WgetDownloadState.downloading));
      expect(status.message, equals('Downloading...'));
      expect(status.filePath, equals('/test.txt'));
      expect(status.downloadedSize, equals(1024));
    });

    test('copyWith creates new instance with updated values', () {
      const original = WgetDownloadStatus(
        state: WgetDownloadState.downloading,
        message: 'Starting...',
      );

      final updated = original.copyWith(
        state: WgetDownloadState.success,
        message: 'Complete',
        filePath: '/file.txt',
      );

      expect(updated.state, equals(WgetDownloadState.success));
      expect(updated.message, equals('Complete'));
      expect(updated.filePath, equals('/file.txt'));
      expect(original.state, equals(WgetDownloadState.downloading)); // Original unchanged
    });

    test('copyWith preserves original values when not specified', () {
      const original = WgetDownloadStatus(
        state: WgetDownloadState.downloading,
        message: 'Downloading...',
        downloadedSize: 512,
      );

      final updated = original.copyWith(downloadedSize: 1024);

      expect(updated.state, equals(WgetDownloadState.downloading));
      expect(updated.message, equals('Downloading...'));
      expect(updated.downloadedSize, equals(1024));
    });

    test('all WgetDownloadState values are available', () {
      expect(WgetDownloadState.values.length, equals(4));
      expect(WgetDownloadState.values, contains(WgetDownloadState.idle));
      expect(WgetDownloadState.values, contains(WgetDownloadState.downloading));
      expect(WgetDownloadState.values, contains(WgetDownloadState.success));
      expect(WgetDownloadState.values, contains(WgetDownloadState.error));
    });

    test('state transitions work correctly', () {
      var status = const WgetDownloadStatus();
      expect(status.state, equals(WgetDownloadState.idle));

      status = status.copyWith(state: WgetDownloadState.downloading);
      expect(status.state, equals(WgetDownloadState.downloading));

      status = status.copyWith(
        state: WgetDownloadState.success,
        message: 'Done',
      );
      expect(status.state, equals(WgetDownloadState.success));
      expect(status.message, equals('Done'));
    });

    test('error state can be created', () {
      const status = WgetDownloadStatus(
        state: WgetDownloadState.error,
        message: 'Connection failed',
      );

      expect(status.state, equals(WgetDownloadState.error));
      expect(status.message, equals('Connection failed'));
    });
  });
}
