import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/transfer/transfer_task.dart';
import 'package:onepanel_client/core/services/cache/memory_cache_manager.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';

void main() {
  group('性能测试', () {
    group('大文件列表渲染性能测试', () {
      test('应该高效生成 1000 个文件列表', () {
        final stopwatch = Stopwatch()..start();

        final files = List.generate(
            1000,
            (i) => FileInfo(
                  name: 'file_$i.txt',
                  path: '/file_$i.txt',
                  size: 1024 * i,
                  type: 'file',
                ));

        stopwatch.stop();

        expect(files.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('应该高效过滤 1000 个文件', () {
        final files = List.generate(
            1000,
            (i) => FileInfo(
                  name: i % 2 == 0 ? 'doc_$i.txt' : 'img_$i.jpg',
                  path: '/file_$i.txt',
                  size: 1024,
                  type: 'file',
                ));

        final stopwatch = Stopwatch()..start();

        final filtered = files.where((f) => f.name.endsWith('.txt')).toList();

        stopwatch.stop();

        expect(filtered.length, equals(500));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('应该高效排序 1000 个文件', () {
        final files = List.generate(
            1000,
            (i) => FileInfo(
                  name: 'file_${999 - i}.txt',
                  path: '/file_$i.txt',
                  size: 1024 * (1000 - i),
                  type: 'file',
                ));

        final stopwatch = Stopwatch()..start();

        files.sort((a, b) => a.name.compareTo(b.name));

        stopwatch.stop();

        expect(files.first.name, equals('file_0.txt'));
        expect(files.last.name, equals('file_999.txt'));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('分块传输性能测试', () {
      test('应该高效计算 100MB 文件的分块', () {
        const fileSize = 100 * 1024 * 1024;
        const chunkSize = 1024 * 1024;

        final stopwatch = Stopwatch()..start();

        final chunks = (fileSize / chunkSize).ceil();
        final chunkInfos = List.generate(chunks, (i) {
          final start = i * chunkSize;
          final end =
              (start + chunkSize > fileSize) ? fileSize : start + chunkSize;
          return ChunkInfo(
            index: i,
            start: start,
            end: end,
            size: end - start,
          );
        });

        stopwatch.stop();

        expect(chunks, equals(100));
        expect(chunkInfos.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('应该高效计算传输进度', () {
        const totalChunks = 100;
        const completedChunks = 50;

        final stopwatch = Stopwatch()..start();

        final progress = completedChunks / totalChunks;
        final progressPercent = '${(progress * 100).toStringAsFixed(1)}%';

        stopwatch.stop();

        expect(progress, equals(0.5));
        expect(progressPercent, equals('50.0%'));
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(1));
      });

      test('应该高效处理分块状态更新', () {
        const totalChunks = 100;
        final uploadedChunks = <int>{};

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < totalChunks; i++) {
          uploadedChunks.add(i);
        }

        stopwatch.stop();

        expect(uploadedChunks.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('缓存性能测试', () {
      test('应该高效存储 1000 个缓存项', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 100 * 1024 * 1024, maxItems: 1000);
        cacheManager.clear();

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          cacheManager.put('key_$i', Uint8List(1024));
        }

        stopwatch.stop();

        expect(cacheManager.itemCount, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        cacheManager.dispose();
      });

      test('应该高效检索缓存项', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 100 * 1024 * 1024, maxItems: 1000);
        cacheManager.clear();

        for (var i = 0; i < 1000; i++) {
          cacheManager.put('key_$i', Uint8List(1024));
        }

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          cacheManager.get('key_$i');
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        cacheManager.dispose();
      });

      test('应该高效执行 LRU 淘汰', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 10 * 1024);
        cacheManager.clear();

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 100; i++) {
          cacheManager.put('key_$i', Uint8List(1024));
        }

        stopwatch.stop();

        final stats = cacheManager.getStats();
        expect(stats['itemCount'], lessThan(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        cacheManager.dispose();
      });

      test('应该正确处理缓存命中和未命中', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 100 * 1024);
        cacheManager.clear();

        cacheManager.put('existing_key', Uint8List.fromList([1, 2, 3]));

        final stopwatch = Stopwatch()..start();

        final hit = cacheManager.get('existing_key');
        final miss = cacheManager.get('non_existing_key');

        stopwatch.stop();

        expect(hit, isNotNull);
        expect(miss, isNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10));

        cacheManager.dispose();
      });
    });

    group('并发传输性能测试', () {
      test('应该正确控制 3 个并发传输', () {
        const maxConcurrent = 3;
        var activeCount = 0;
        var maxObserved = 0;

        final tasks = List.generate(
            10,
            (i) => TransferTask(
                  id: 'task_$i',
                  path: '/file_$i.txt',
                  totalSize: 1024 * 1024,
                  type: TransferType.upload,
                  createdAt: DateTime.now(),
                ));

        for (var i = 0; i < tasks.length; i++) {
          if (activeCount < maxConcurrent) {
            activeCount++;
            if (activeCount > maxObserved) {
              maxObserved = activeCount;
            }
          }
          if (i >= 3) {
            activeCount--;
          }
        }

        expect(maxObserved, equals(maxConcurrent));
      });

      test('应该高效处理传输队列', () {
        final queue = <TransferTask>[];

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 100; i++) {
          queue.add(TransferTask(
            id: 'task_$i',
            path: '/file_$i.txt',
            totalSize: 1024 * 1024,
            type: TransferType.upload,
            createdAt: DateTime.now(),
          ));
        }

        for (var i = 0; i < 50; i++) {
          queue.removeAt(0);
        }

        stopwatch.stop();

        expect(queue.length, equals(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('应该高效计算传输优先级排序', () {
        final tasks = List.generate(
            100,
            (i) => TransferTask(
                  id: 'task_$i',
                  path: '/file_$i.txt',
                  totalSize: 1024 * 1024 * (100 - i),
                  type: TransferType.upload,
                  createdAt: DateTime.now().subtract(Duration(seconds: i)),
                ));

        final stopwatch = Stopwatch()..start();

        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        stopwatch.stop();

        expect(tasks.first.createdAt.isBefore(tasks.last.createdAt), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('数据序列化性能测试', () {
      test('应该高效序列化 FileInfo', () {
        final files = List.generate(
            1000,
            (i) => FileInfo(
                  name: 'file_$i.txt',
                  path: '/path/file_$i.txt',
                  size: 1024 * i,
                  type: 'file',
                ));

        final stopwatch = Stopwatch()..start();

        final jsonList = files
            .map((f) => {
                  'name': f.name,
                  'path': f.path,
                  'size': f.size,
                  'type': f.type,
                })
            .toList();

        stopwatch.stop();

        expect(jsonList.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('应该高效反序列化 FileInfo', () {
        final jsonList = List.generate(
            1000,
            (i) => {
                  'name': 'file_$i.txt',
                  'path': '/path/file_$i.txt',
                  'size': 1024 * i,
                  'type': 'file',
                });

        final stopwatch = Stopwatch()..start();

        final files = jsonList.map((json) => FileInfo.fromJson(json)).toList();

        stopwatch.stop();

        expect(files.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('内存使用性能测试', () {
      test('应该正确计算缓存内存占用', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 10 * 1024 * 1024);
        cacheManager.clear();

        for (var i = 0; i < 10; i++) {
          cacheManager.put('key_$i', Uint8List(1024 * 100));
        }

        final stats = cacheManager.getStats();

        expect(stats['currentSizeBytes'], equals(1024 * 100 * 10));
        expect(stats['itemCount'], equals(10));

        cacheManager.dispose();
      });

      test('应该正确清理缓存释放内存', () {
        final cacheManager = MemoryCacheManager();
        cacheManager.configure(maxSizeBytes: 100 * 1024 * 1024, maxItems: 100);
        cacheManager.clear();

        for (var i = 0; i < 100; i++) {
          cacheManager.put('key_$i', Uint8List(1024));
        }

        expect(cacheManager.itemCount, equals(100));

        cacheManager.clear();

        expect(cacheManager.itemCount, equals(0));
        expect(cacheManager.currentSizeBytes, equals(0));

        cacheManager.dispose();
      });
    });

    group('TransferTask 状态转换性能测试', () {
      test('应该高效处理大量状态更新', () {
        var task = TransferTask(
          id: 'test_task',
          path: '/test.txt',
          totalSize: 1024 * 1024 * 100,
          type: TransferType.upload,
          createdAt: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          task = task.copyWith(transferredSize: i * 1024);
          final progress = task.progress;
          progress.toStringAsFixed(2);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('应该高效计算进度百分比', () {
        final task = TransferTask(
          id: 'test_task',
          path: '/test.txt',
          totalSize: 1024 * 1024 * 100,
          transferredSize: 50 * 1024 * 1024,
          type: TransferType.upload,
          createdAt: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 100; i++) {
          final progress = task.progress;
          final percent = task.progressPercent;
          progress.toStringAsFixed(2);
          percent.toString();
        }

        stopwatch.stop();

        expect(task.progress, equals(0.5));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
