import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_recycle.dart';

void main() {
  group('FileRecycle 模型测试', () {
    group('RecycleBinItem', () {
      test('应该正确创建回收站项目', () {
        final item = RecycleBinItem(
          sourcePath: '/original/path/file.txt',
          name: 'file.txt',
          size: 1024,
          isDir: false,
          rName: 'r_file.txt',
          from: '/original/path',
        );

        expect(item.sourcePath, equals('/original/path/file.txt'));
        expect(item.name, equals('file.txt'));
        expect(item.size, equals(1024));
        expect(item.isDir, isFalse);
        expect(item.rName, equals('r_file.txt'));
        expect(item.from, equals('/original/path'));
      });

      test('应该正确从 JSON 解析', () {
        final json = {
          'sourcePath': '/original/path/file.txt',
          'name': 'file.txt',
          'size': 1024,
          'isDir': false,
          'rName': 'r_file.txt',
          'from': '/original/path',
        };

        final item = RecycleBinItem.fromJson(json);

        expect(item.sourcePath, equals('/original/path/file.txt'));
        expect(item.name, equals('file.txt'));
        expect(item.size, equals(1024));
        expect(item.isDir, isFalse);
      });

      test('应该正确处理目录项目', () {
        final item = RecycleBinItem(
          sourcePath: '/original/path/mydir',
          name: 'mydir',
          size: 0,
          isDir: true,
          rName: 'r_mydir',
          from: '/original/path',
        );

        expect(item.isDir, isTrue);
        expect(item.name, equals('mydir'));
      });

      test('应该正确序列化为 JSON', () {
        final item = RecycleBinItem(
          sourcePath: '/path/file.txt',
          name: 'file.txt',
          size: 1024,
          isDir: false,
          rName: 'r_file.txt',
          from: '/path',
        );

        final json = item.toJson();

        expect(json['sourcePath'], equals('/path/file.txt'));
        expect(json['name'], equals('file.txt'));
        expect(json['size'], equals(1024));
        expect(json['isDir'], isFalse);
      });

      test('应该支持相等性比较', () {
        final item1 = RecycleBinItem(
          sourcePath: '/path/file.txt',
          name: 'file.txt',
          size: 1024,
          isDir: false,
          rName: 'r_file.txt',
          from: '/path',
        );

        final item2 = RecycleBinItem(
          sourcePath: '/path/file.txt',
          name: 'file.txt',
          size: 1024,
          isDir: false,
          rName: 'r_file.txt',
          from: '/path',
        );

        expect(item1, equals(item2));
      });
    });

    group('RecycleBinReduceRequest', () {
      test('应该正确创建恢复请求', () {
        const request = RecycleBinReduceRequest(
          rName: 'r_file.txt',
          from: '/original/path',
          name: 'file.txt',
        );

        expect(request.rName, equals('r_file.txt'));
        expect(request.from, equals('/original/path'));
        expect(request.name, equals('file.txt'));
      });

      test('应该正确序列化为 JSON', () {
        const request = RecycleBinReduceRequest(
          rName: 'r_file.txt',
          from: '/original/path',
          name: 'file.txt',
        );

        final json = request.toJson();

        expect(json['rName'], equals('r_file.txt'));
        expect(json['from'], equals('/original/path'));
        expect(json['name'], equals('file.txt'));
      });
    });

    group('FileRecycleReduce', () {
      test('应该正确创建清理请求', () {
        const reduce = FileRecycleReduce(
          days: 30,
          count: 100,
          byDate: true,
        );

        expect(reduce.days, equals(30));
        expect(reduce.count, equals(100));
        expect(reduce.byDate, isTrue);
      });

      test('应该正确序列化为 JSON', () {
        const reduce = FileRecycleReduce(
          days: 30,
          byDate: true,
        );

        final json = reduce.toJson();

        expect(json['days'], equals(30));
        expect(json['byDate'], isTrue);
      });
    });

    group('FileRecycleResult', () {
      test('应该正确创建清理结果', () {
        const result = FileRecycleResult(
          deletedCount: 10,
          totalSize: 1024 * 1024,
          message: '清理完成',
        );

        expect(result.deletedCount, equals(10));
        expect(result.totalSize, equals(1024 * 1024));
        expect(result.message, equals('清理完成'));
      });

      test('应该正确从 JSON 解析', () {
        final json = {
          'deletedCount': 5,
          'totalSize': 512 * 1024,
          'message': 'Success',
        };

        final result = FileRecycleResult.fromJson(json);

        expect(result.deletedCount, equals(5));
        expect(result.totalSize, equals(512 * 1024));
        expect(result.message, equals('Success'));
      });
    });

    group('FileRecycleStatus', () {
      test('应该正确创建回收站状态', () {
        final status = FileRecycleStatus(
          fileCount: 100,
          totalSize: 1024 * 1024 * 100,
        );

        expect(status.fileCount, equals(100));
        expect(status.totalSize, equals(1024 * 1024 * 100));
      });

      test('应该正确从 JSON 解析', () {
        final json = {
          'fileCount': 50,
          'totalSize': 1024 * 1024 * 50,
          'oldestFile': 'old.txt',
          'newestFile': 'new.txt',
        };

        final status = FileRecycleStatus.fromJson(json);

        expect(status.fileCount, equals(50));
        expect(status.totalSize, equals(1024 * 1024 * 50));
        expect(status.oldestFile, equals('old.txt'));
        expect(status.newestFile, equals('new.txt'));
      });
    });
  });
}
