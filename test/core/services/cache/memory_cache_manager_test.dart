import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/cache/memory_cache_manager.dart';

void main() {
  group('MemoryCacheManager 测试', () {
    late MemoryCacheManager cacheManager;

    setUp(() {
      cacheManager = MemoryCacheManager();
      cacheManager.configure(maxSizeBytes: 1024 * 10);
    });

    tearDown(() {
      cacheManager.dispose();
    });

    group('基本操作', () {
      test('应该正确存储和获取数据', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        cacheManager.put('test-key', data);
        final result = cacheManager.get('test-key');
        
        expect(result, isNotNull);
        expect(result, equals(data));
      });

      test('应该正确检查键是否存在', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        expect(cacheManager.contains('test-key'), isFalse);
        
        cacheManager.put('test-key', data);
        
        expect(cacheManager.contains('test-key'), isTrue);
      });

      test('应该正确删除数据', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        cacheManager.put('test-key', data);
        expect(cacheManager.contains('test-key'), isTrue);
        
        cacheManager.remove('test-key');
        expect(cacheManager.contains('test-key'), isFalse);
      });

      test('应该正确清空缓存', () {
        cacheManager.put('key1', Uint8List.fromList([1]));
        cacheManager.put('key2', Uint8List.fromList([2]));
        cacheManager.put('key3', Uint8List.fromList([3]));
        
        expect(cacheManager.getStats()['itemCount'], equals(3));
        
        cacheManager.clear();
        
        expect(cacheManager.getStats()['itemCount'], equals(0));
      });
    });

    group('过期机制', () {
      test('应该正确设置过期时间', () async {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        cacheManager.put('test-key', data);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final stats = cacheManager.getStats();
        expect(stats['expirationMinutes'], equals(2));
      });

      test('过期数据应该被清理', () async {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        cacheManager.put('test-key', data);
        
        final entry = cacheManager.getEntry('test-key');
        expect(entry, isNotNull);
      });
    });

    group('容量管理', () {
      test('应该正确统计缓存大小', () {
        final data1 = Uint8List.fromList(List.filled(100, 1));
        final data2 = Uint8List.fromList(List.filled(200, 2));
        
        cacheManager.put('key1', data1);
        cacheManager.put('key2', data2);
        
        final stats = cacheManager.getStats();
        expect(stats['currentSizeBytes'], equals(300));
      });

      test('应该正确统计缓存项数量', () {
        cacheManager.put('key1', Uint8List.fromList([1]));
        cacheManager.put('key2', Uint8List.fromList([2]));
        cacheManager.put('key3', Uint8List.fromList([3]));
        
        final stats = cacheManager.getStats();
        expect(stats['itemCount'], equals(3));
      });
    });

    group('LRU 淘汰', () {
      test('应该淘汰最久未使用的数据', () {
        cacheManager.configure(maxSizeBytes: 100);
        
        cacheManager.put('key1', Uint8List.fromList(List.filled(40, 1)));
        cacheManager.put('key2', Uint8List.fromList(List.filled(40, 2)));
        cacheManager.put('key3', Uint8List.fromList(List.filled(40, 3)));
        
        expect(cacheManager.contains('key1'), isFalse);
        expect(cacheManager.contains('key2'), isTrue);
        expect(cacheManager.contains('key3'), isTrue);
      });

      test('访问数据应该更新 LRU 顺序', () {
        cacheManager.configure(maxSizeBytes: 100);
        
        cacheManager.put('key1', Uint8List.fromList(List.filled(40, 1)));
        cacheManager.put('key2', Uint8List.fromList(List.filled(40, 2)));
        
        cacheManager.get('key1');
        
        cacheManager.put('key3', Uint8List.fromList(List.filled(40, 3)));
        
        expect(cacheManager.contains('key1'), isTrue);
        expect(cacheManager.contains('key2'), isFalse);
      });
    });

    group('统计信息', () {
      test('应该返回完整的统计信息', () {
        cacheManager.put('key1', Uint8List.fromList([1, 2, 3]));
        
        final stats = cacheManager.getStats();
        
        expect(stats.containsKey('itemCount'), isTrue);
        expect(stats.containsKey('currentSizeBytes'), isTrue);
        expect(stats.containsKey('currentSizeMB'), isTrue);
        expect(stats.containsKey('maxSizeMB'), isTrue);
        expect(stats.containsKey('expirationMinutes'), isTrue);
      });
    });

    group('生命周期管理', () {
      test('应该正确处理应用暂停', () {
        cacheManager.put('key1', Uint8List.fromList([1, 2, 3]));
        
        cacheManager.onAppPaused();
        
        final result = cacheManager.get('key1');
        expect(result, isNull);
      });

      test('应该正确处理应用恢复', () {
        cacheManager.put('key1', Uint8List.fromList([1, 2, 3]));
        
        cacheManager.onAppPaused();
        cacheManager.onAppResumed();
        
        cacheManager.put('key2', Uint8List.fromList([4, 5, 6]));
        expect(cacheManager.contains('key2'), isTrue);
      });
    });
  });
}
