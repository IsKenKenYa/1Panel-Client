import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/repositories/database_repository.dart';

void main() {
  group('DatabaseRepository.confFileType', () {
    test('实例类型追加 -conf 后缀，与面板配置文件接口契约一致', () {
      // 回归：直接传实例类型（mysql）请求 /databases/common/load/file，
      // 面板返回 500「无法找到请求的资源」，数据库详情整页加载失败。
      expect(DatabaseRepository.confFileType('mysql'), 'mysql-conf');
      expect(DatabaseRepository.confFileType('mariadb'), 'mariadb-conf');
      expect(DatabaseRepository.confFileType('postgresql'), 'postgresql-conf');
    });
  });

  test('远程连接读取 address 并允许缺少状态字段', () {
    final response = <String, dynamic>{
      'id': 29,
      'name': 'postgres-remote',
      'type': 'postgresql',
      'version': '18.x',
      'address': 'database.example.com',
      'port': 5432,
    };

    final item = DatabaseListItem.fromRemoteInfo(DatabaseInfo.fromJson(response));

    expect(item.id, 29);
    expect(item.address, 'database.example.com');
    expect(item.status, isNull);
    response.remove('id');
    expect(() => DatabaseInfo.fromJson(response), throwsA(isA<TypeError>()));
  });
}
