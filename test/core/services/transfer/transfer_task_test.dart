import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/transfer/transfer_task.dart';

void main() {
  group('TransferTask 模型测试', () {
    group('TransferTask', () {
      test('应该正确创建上传任务', () {
        final task = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          fileName: 'file.txt',
          totalSize: 1024 * 1024,
          type: TransferType.upload,
          totalChunks: 10,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(task.id, equals('test-001'));
        expect(task.path, equals('/test/file.txt'));
        expect(task.fileName, equals('file.txt'));
        expect(task.totalSize, equals(1024 * 1024));
        expect(task.type, equals(TransferType.upload));
        expect(task.status, equals(TransferStatus.pending));
        expect(task.totalChunks, equals(10));
      });

      test('应该正确计算进度', () {
        final task = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          transferredSize: 500,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(task.progress, equals(0.5));
        expect(task.progressPercent, equals('50.0%'));
      });

      test('应该正确处理零大小文件', () {
        final task = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 0,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(task.progress, equals(0));
        expect(task.progressPercent, equals('0.0%'));
      });

      test('应该正确判断可恢复状态', () {
        final pendingTask = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final pausedTask = TransferTask(
          id: 'test-002',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.paused,
          createdAt: DateTime(2024, 1, 1),
        );

        final failedTask = TransferTask(
          id: 'test-003',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.failed,
          createdAt: DateTime(2024, 1, 1),
        );

        final completedTask = TransferTask(
          id: 'test-004',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.completed,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(pendingTask.isResumable, isFalse);
        expect(pausedTask.isResumable, isTrue);
        expect(failedTask.isResumable, isTrue);
        expect(completedTask.isResumable, isFalse);
      });

      test('应该正确判断活动状态', () {
        final runningTask = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.running,
          createdAt: DateTime(2024, 1, 1),
        );

        final pendingTask = TransferTask(
          id: 'test-002',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.pending,
          createdAt: DateTime(2024, 1, 1),
        );

        final completedTask = TransferTask(
          id: 'test-003',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.completed,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(runningTask.isActive, isTrue);
        expect(pendingTask.isActive, isTrue);
        expect(completedTask.isActive, isFalse);
      });

      test('应该正确使用 copyWith', () {
        final task = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        final updatedTask = task.copyWith(
          status: TransferStatus.running,
          transferredSize: 500,
        );

        expect(updatedTask.status, equals(TransferStatus.running));
        expect(updatedTask.transferredSize, equals(500));
        expect(updatedTask.id, equals(task.id));
        expect(updatedTask.path, equals(task.path));
      });

      test('应该支持相等性比较', () {
        final task1 = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        final task2 = TransferTask(
          id: 'test-001',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        final task3 = TransferTask(
          id: 'test-002',
          path: '/test/file.txt',
          totalSize: 1000,
          type: TransferType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(task1, equals(task2));
        expect(task1, isNot(equals(task3)));
      });
    });

    group('TransferType', () {
      test('应该包含 upload 类型', () {
        expect(TransferType.values, contains(TransferType.upload));
      });
    });

    group('TransferStatus', () {
      test('应该包含所有状态', () {
        expect(TransferStatus.values, contains(TransferStatus.pending));
        expect(TransferStatus.values, contains(TransferStatus.running));
        expect(TransferStatus.values, contains(TransferStatus.paused));
        expect(TransferStatus.values, contains(TransferStatus.completed));
        expect(TransferStatus.values, contains(TransferStatus.failed));
        expect(TransferStatus.values, contains(TransferStatus.cancelled));
      });
    });

    group('ChunkInfo', () {
      test('应该正确创建分块信息', () {
        const chunk = ChunkInfo(
          index: 0,
          start: 0,
          end: 1024,
          size: 1024,
        );

        expect(chunk.index, equals(0));
        expect(chunk.start, equals(0));
        expect(chunk.end, equals(1024));
        expect(chunk.size, equals(1024));
        expect(chunk.isUploaded, isFalse);
      });

      test('应该正确使用 copyWith', () {
        const chunk = ChunkInfo(
          index: 0,
          start: 0,
          end: 1024,
          size: 1024,
        );

        final uploadedChunk = chunk.copyWith(isUploaded: true);

        expect(uploadedChunk.isUploaded, isTrue);
        expect(uploadedChunk.index, equals(chunk.index));
      });

      test('应该支持相等性比较', () {
        const chunk1 = ChunkInfo(index: 0, start: 0, end: 1024, size: 1024);
        const chunk2 = ChunkInfo(index: 0, start: 0, end: 1024, size: 1024);
        const chunk3 = ChunkInfo(index: 1, start: 1024, end: 2048, size: 1024);

        expect(chunk1, equals(chunk2));
        expect(chunk1, isNot(equals(chunk3)));
      });
    });
  });
}
