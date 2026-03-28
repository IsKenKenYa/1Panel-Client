import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/features/files/providers/file_preview_provider.dart';
import 'package:onepanel_client/features/files/services/file_preview_service.dart';

class _FakeFilePreviewService extends FilePreviewService {
  _FakeFilePreviewService({
    this.content = 'line1\nline2',
    this.bytes = const <int>[1, 2, 3],
  });

  final String content;
  final String preview = 'line1\nline2\nline3';
  final List<int> bytes;

  @override
  Future<void> ensureServer() async {}

  @override
  Future<String> getFileContent(String path) async => content;

  @override
  Future<String> previewFile(
    String path, {
    int? line,
    int? limit,
  }) async {
    return preview;
  }

  @override
  Future<List<int>> downloadFileBytes(String path) async => bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FilePreviewProvider loads text content', () async {
    final provider = FilePreviewProvider(
      filePath: '/a.txt',
      fileName: 'a.txt',
      service: _FakeFilePreviewService(content: 'hello'),
      cacheLoader: ({
        required String filePath,
        required String fileName,
        required Future<Uint8List> Function() downloadFn,
        required CacheStrategy strategy,
      }) async {
        return CacheResult(
          data: Uint8List.fromList(const <int>[1, 2]),
          source: CacheSource.network,
          fileName: fileName,
        );
      },
      tempSaver: (data, fileName) async => '/tmp/$fileName',
    );

    await provider.initialize(
      cacheStrategy: CacheStrategy.memoryOnly,
      cacheMaxSizeMB: 10,
    );

    expect(provider.fileType, PreviewFileType.text);
    expect(provider.content, 'hello');
    expect(provider.isLoading, isFalse);
  });

  test('FilePreviewProvider prepares binary preview and awaits media init',
      () async {
    final provider = FilePreviewProvider(
      filePath: '/movie.mp4',
      fileName: 'movie.mp4',
      service:
          _FakeFilePreviewService(bytes: Uint8List.fromList(<int>[1, 2, 3])),
      cacheLoader: ({
        required String filePath,
        required String fileName,
        required Future<Uint8List> Function() downloadFn,
        required CacheStrategy strategy,
      }) async {
        return CacheResult(
          data: Uint8List.fromList(const <int>[1, 2, 3]),
          source: CacheSource.network,
          fileName: fileName,
        );
      },
      tempSaver: (data, fileName) async => '/tmp/$fileName',
    );

    await provider.initialize(
      cacheStrategy: CacheStrategy.memoryOnly,
      cacheMaxSizeMB: 10,
    );

    expect(provider.fileType, PreviewFileType.video);
    expect(provider.localFilePath, isNotNull);
    expect(provider.awaitingMediaInitialization, isTrue);

    provider.completeMediaInitialization();
    expect(provider.isLoading, isFalse);
  });
}
