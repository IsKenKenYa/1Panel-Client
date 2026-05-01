import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/database_models.dart';

void main() {
  test('mysql search result keeps db type and target instance separate', () {
    final item = DatabaseListItem.fromMysqlJson(const <String, dynamic>{
      'id': 1,
      'name': 'gitea_guangzhou',
      'type': 'mysql',
      'mysqlName': 'ruoyi-mysql',
      'from': 'local',
      'database': 'gitea_guangzhou',
      'username': 'root',
    });

    expect(item.engine, 'mysql');
    expect(item.lookupName, 'ruoyi-mysql');
    expect(item.name, 'gitea_guangzhou');
  });

  test('database option keeps target instance as lookup name', () {
    final item = DatabaseListItem.fromDatabaseOption(
      const <String, dynamic>{
        'id': 1,
        'type': 'mysql',
        'from': 'local',
        'database': 'ruoyi-mysql',
        'name': 'gitea_guangzhou',
      },
      DatabaseScope.mysql,
    );

    expect(item.engine, 'mysql');
    expect(item.lookupName, 'ruoyi-mysql');
    expect(item.instanceLabel, 'gitea_guangzhou');
  });
}
