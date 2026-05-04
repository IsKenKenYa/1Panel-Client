import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';

/// 回归测试：验证 CronjobListQuery.order 默认值为 'descending' 而非 'null'
///
/// 问题描述：
/// /api/v2/cronjobs/search 端点要求 order 字段为有效值（ascending/descending），
/// 但客户端模型中 order 默认值为字符串字面量 'null'，导致：
///   参数错误: Key: 'PageCronjob.OrderBy' Error:Field validation for 'OrderBy' failed on the 'required' tag
///   Key: 'PageCronjob.Order' Error:Field validation for 'Order' failed on the 'required' tag
///
/// 原因分析：
/// CronjobListQuery 构造函数中 this.order = 'null' 使用了字符串字面量 'null'
/// 而非 Dart 的 null 值。服务端将字符串 'null' 视为无效值，拒绝请求。
///
/// 修复方案：
/// 将 CronjobListQuery.order 默认值从 'null' 改为 'descending'，
/// 与 PageContainer 等其他分页查询模型保持一致。
void main() {
  group('CronjobListQuery.order 默认值验证', () {
    test('默认构造函数 order 应为 descending', () {
      const query = CronjobListQuery();

      expect(query.order, equals('descending'),
          reason: 'order default should be "descending", not "null"');
      expect(query.order, isNot(equals('null')),
          reason: 'order should NOT be the string literal "null"');
    });

    test('toJson 应输出有效的 order 值', () {
      const query = CronjobListQuery();
      final json = query.toJson();

      expect(json['order'], equals('descending'));
      expect(json['order'], isNot(equals('null')));
      expect(json['order'], isA<String>());
      expect((json['order'] as String).isNotEmpty, isTrue);
    });

    test('自定义 order 值应被保留', () {
      const query = CronjobListQuery(order: 'ascending');
      final json = query.toJson();

      expect(json['order'], equals('ascending'));
    });

    test('完整的 toJson 应包含所有分页必需字段', () {
      const query = CronjobListQuery();
      final json = query.toJson();

      expect(json.containsKey('page'), isTrue);
      expect(json.containsKey('pageSize'), isTrue);
      expect(json.containsKey('orderBy'), isTrue);
      expect(json.containsKey('order'), isTrue);

      // 所有字段都不应为 null 或空字符串
      expect(json['page'], equals(1));
      expect(json['pageSize'], equals(20));
      expect(json['orderBy'], equals('createdAt'));
      expect(json['order'], equals('descending'));
    });

    test('orderBy 默认值应为 createdAt', () {
      const query = CronjobListQuery();

      expect(query.orderBy, equals('createdAt'));
    });
  });
}
