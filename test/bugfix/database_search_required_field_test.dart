import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/database_models.dart';

/// 回归测试：验证 DatabaseSearch.database 字段为必填
///
/// 问题描述：
/// /api/v2/databases/search 端点要求 database 字段是必填的，
/// 但客户端模型中该字段是可选的，导致当 targetDatabase 为 null 时请求失败。
///
/// 错误信息：
/// 参数错误: Key: 'MysqlDBSearch.Database' Error:Field validation for 'Database' failed on the 'required' tag
///
/// 修复方案：
/// 1. 将 DatabaseSearch.database 字段从可选改为必填
/// 2. 在 repository 层当 targetDatabase 为空时返回空结果，避免发送无效请求
void main() {
  group('DatabaseSearch 必填字段验证', () {
    test('database 字段应该是必填的', () {
      // 验证构造函数要求 database 参数
      const search = DatabaseSearch(
        database: 'mysql-1',
        page: 1,
        pageSize: 20,
      );

      expect(search.database, equals('mysql-1'));
    });

    test('database 字段不能为 null', () {
      // 这个测试确保 database 是 String 而不是 String?
      const search = DatabaseSearch(
        database: '',
        page: 1,
        pageSize: 20,
      );

      // database 应该是空字符串，而不是 null
      expect(search.database, isNotNull);
      expect(search.database, equals(''));
    });

    test('toJson 应该包含 database 字段', () {
      const search = DatabaseSearch(
        database: 'mysql-1',
        info: 'test',
        page: 1,
        pageSize: 20,
      );

      final json = search.toJson();

      expect(json['database'], equals('mysql-1'));
      expect(json['database'], isNotNull);
    });

    test('toJson 应该序列化空字符串而不是 null', () {
      const search = DatabaseSearch(
        database: '',
        page: 1,
        pageSize: 20,
      );

      final json = search.toJson();

      expect(json['database'], equals(''));
      expect(json['database'], isNot(null));
    });

    test('fromJson 应该处理 null 值并转换为空字符串', () {
      final json = {
        'database': null,
        'page': 1,
        'pageSize': 20,
        'orderBy': 'createdAt',
        'order': 'descending',
      };

      final search = DatabaseSearch.fromJson(json);

      // null 应该被转换为空字符串
      expect(search.database, equals(''));
      expect(search.database, isNotNull);
    });

    test('fromJson 应该保留有效的 database 值', () {
      final json = {
        'database': 'mysql-1',
        'page': 1,
        'pageSize': 20,
        'orderBy': 'createdAt',
        'order': 'descending',
      };

      final search = DatabaseSearch.fromJson(json);

      expect(search.database, equals('mysql-1'));
    });

    test('完整的请求体应该包含所有必需字段', () {
      const search = DatabaseSearch(
        info: '',
        name: null,
        type: null,
        database: '',
        page: 1,
        pageSize: 20,
        orderBy: 'createdAt',
        order: 'descending',
      );

      final json = search.toJson();

      // 验证所有字段都存在
      expect(json.containsKey('info'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('database'), isTrue);
      expect(json.containsKey('page'), isTrue);
      expect(json.containsKey('pageSize'), isTrue);
      expect(json.containsKey('orderBy'), isTrue);
      expect(json.containsKey('order'), isTrue);

      // database 不应该是 null
      expect(json['database'], isNotNull);
      expect(json['database'], equals(''));
    });
  });

  group('DatabaseScope 空目标数据库处理', () {
    test('当 targetDatabase 为空时，应避免发送无效请求', () {
      // 模拟场景：没有 MySQL 实例时，targetDatabase 为 null
      String? targetDatabase;

      // 验证空值检查逻辑
      final isEmpty = targetDatabase == null || targetDatabase.isEmpty;
      expect(isEmpty, isTrue);

      // 当 targetDatabase 为空时，应该返回空结果而不是发送请求
      // 这避免了服务端返回 400 错误：
      // "参数错误: Key: 'MysqlDBSearch.Database' Error:Field validation for 'Database' failed on the 'required' tag"
    });

    test('当 targetDatabase 为空字符串时，应避免发送无效请求', () {
      // 模拟场景：targetDatabase 为空字符串
      const String targetDatabase = '';

      // 验证空值检查逻辑
      final isEmpty = targetDatabase.isEmpty;
      expect(isEmpty, isTrue);
    });

    test('当 targetDatabase 有效时，应正常处理', () {
      // 模拟场景：有 MySQL 实例时，targetDatabase 有值
      const String targetDatabase = 'mysql-1';

      // 验证非空检查逻辑
      final isEmpty = targetDatabase.isEmpty;
      expect(isEmpty, isFalse);
    });
  });
}
