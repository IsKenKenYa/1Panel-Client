import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_transfer.dart';
import 'package:onepanel_client/features/files/services/file_transfer_service.dart';

void main() {
  group('FileChunkUpload', () {
    test('carries the multipart fields the server expects', () {
      const request = FileChunkUpload(
        uploadID: 'upload-1',
        filename: 'image.iso',
        path: '/opt/1panel/tmp',
        chunkBytes: <int>[1, 2, 3],
        chunkIndex: 2,
        chunkCount: 10,
        offset: 2 * 1024 * 1024,
        fileSize: 10 * 1024 * 1024,
      );

      expect(request.uploadID, 'upload-1');
      expect(request.filename, 'image.iso');
      expect(request.path, '/opt/1panel/tmp');
      expect(request.chunkIndex, 2);
      expect(request.chunkCount, 10);
      expect(request.offset, 2097152);
      expect(request.fileSize, 10485760);
      expect(request.overwrite, isTrue);
    });

    test('two requests differ only by chunk index and offset', () {
      const base = FileChunkUpload(
        uploadID: 'upload-1',
        filename: 'image.iso',
        path: '/opt/1panel/tmp',
        chunkBytes: <int>[1],
        chunkIndex: 0,
        chunkCount: 4,
        offset: 0,
        fileSize: 4 * 1024 * 1024,
      );
      final next = FileChunkUpload(
        uploadID: base.uploadID,
        filename: base.filename,
        path: base.path,
        chunkBytes: base.chunkBytes,
        chunkIndex: 1,
        chunkCount: base.chunkCount,
        offset: 1024 * 1024,
        fileSize: base.fileSize,
      );

      expect(base == next, isFalse);
      expect(base.uploadID == next.uploadID, isTrue);
      expect(next.offset, 1048576);
    });
  });

  group('FileChunkResult', () {
    test('parses the server success envelope', () {
      final result = FileChunkResult.fromJson(<String, dynamic>{
        'success': true,
        'totalChunks': 10,
        'uploadedChunks': 3,
      });

      expect(result.success, isTrue);
      expect(result.totalChunks, 10);
      expect(result.uploadedChunks, 3);
    });

    test('defaults success to false when the field is absent', () {
      final result = FileChunkResult.fromJson(<String, dynamic>{});

      expect(result.success, isFalse);
      expect(result.totalChunks, isNull);
    });
  });

  group('chunk partition', () {
    test('chunk size matches the server single-chunk ceiling', () {
      expect(FileTransferService.chunkSize, 1024 * 1024);
    });

    test('chunk count and final offset follow the server formula', () {
      const totalSize = 5 * 1024 * 1024 + 1;
      final totalChunks =
          (totalSize / FileTransferService.chunkSize).ceil();
      final lastStart = (totalChunks - 1) * FileTransferService.chunkSize;
      final lastEnd =
          lastStart + FileTransferService.chunkSize > totalSize
              ? totalSize
              : lastStart + FileTransferService.chunkSize;

      expect(totalChunks, 6);
      expect(lastStart, 5 * 1024 * 1024);
      expect(lastEnd, totalSize);
      expect(lastEnd - lastStart, 1);
    });
  });
}
