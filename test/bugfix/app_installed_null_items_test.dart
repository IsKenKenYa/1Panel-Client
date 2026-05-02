import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/app_models.dart';

/// 回归测试：验证 PageResult 能正确处理 items 为 null 的情况
/// 
/// 问题背景：
/// - API 返回 {code: 200, data: {total: 0, items: null}} 时应用崩溃
/// - 错误信息：type 'Null' is not a subtype of type 'List<dynamic>' in type cast
/// 
/// 修复方案：
/// - 在 PageResult 模型中添加 @JsonKey(defaultValue: []) 和 @JsonKey(defaultValue: 0)
/// - 确保 items 为 null 时返回空列表，total 为 null 时返回 0
void main() {
  group('PageResult null safety', () {
    test('should handle null items gracefully', () {
      // 模拟 API 返回 items 为 null 的情况
      final json = {
        'total': 0,
        'items': null,
      };

      // 应该不会抛出异常
      final result = PageResult<AppInstallInfo>.fromJson(
        json,
        (item) => AppInstallInfo.fromJson(item as Map<String, dynamic>),
      );

      // 验证结果
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });

    test('should handle null total gracefully', () {
      // 模拟 API 返回 total 为 null 的情况
      final json = {
        'total': null,
        'items': [],
      };

      // 应该不会抛出异常
      final result = PageResult<AppInstallInfo>.fromJson(
        json,
        (item) => AppInstallInfo.fromJson(item as Map<String, dynamic>),
      );

      // 验证结果
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });

    test('should handle both null items and total gracefully', () {
      // 模拟 API 返回两者都为 null 的情况
      final json = {
        'total': null,
        'items': null,
      };

      // 应该不会抛出异常
      final result = PageResult<AppInstallInfo>.fromJson(
        json,
        (item) => AppInstallInfo.fromJson(item as Map<String, dynamic>),
      );

      // 验证结果
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });

    test('should handle normal response correctly', () {
      // 模拟正常的 API 返回
      final json = {
        'total': 2,
        'items': [
          {
            'id': 1,
            'name': 'test-app-1',
            'appId': 100,
            'appKey': 'test-key-1',
            'appType': 'runtime',
            'appDetailId': 1000,
            'version': '1.0.0',
            'status': 'Running',
            'createdAt': '2024-01-01T00:00:00Z',
          },
          {
            'id': 2,
            'name': 'test-app-2',
            'appId': 101,
            'appKey': 'test-key-2',
            'appType': 'runtime',
            'appDetailId': 1001,
            'version': '2.0.0',
            'status': 'Stopped',
            'createdAt': '2024-01-02T00:00:00Z',
          },
        ],
      };

      // 应该正确解析
      final result = PageResult<AppInstallInfo>.fromJson(
        json,
        (item) => AppInstallInfo.fromJson(item as Map<String, dynamic>),
      );

      // 验证结果
      expect(result.items, hasLength(2));
      expect(result.total, 2);
      expect(result.items[0].name, 'test-app-1');
      expect(result.items[1].name, 'test-app-2');
    });
  });
}
