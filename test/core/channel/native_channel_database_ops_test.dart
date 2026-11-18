import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 数据库页依赖的建/删/改通道契约（B11）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createDatabase (native channel write handler)', () {
    test('缺 name 返回失败结构（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createDatabase(
        {'name': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('回归：本地建库缺 database（目标实例名）快速失败', () async {
      // 服务端 MysqlDBCreate required：database/format/permission
      // （2026-09-08 生产面板 400 实测）。本地路径缺 database 时
      // handler 必须快速失败而非发出注定被拒的请求。
      final result = await NativeChannelWriteHandlers.createDatabase(
        {'name': 'app_db'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('database is required'));
    });

    test('dispatch 路由 createDatabase 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createDatabase',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('deleteDatabase (native channel write handler)', () {
    test('缺 id 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.deleteDatabase(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('dispatch 路由 deleteDatabase 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'deleteDatabase',
        {'id': 'x'},
      );

      // 无有效服务器时底层失败，handler 必须返回失败结构而非抛出。
      expect(result.containsKey('success'), isTrue);
    });
  });

  group('updateDatabaseDescription / changeDatabasePassword', () {
    test('description 缺 lookupName 且缺 name 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateDatabaseDescription(
        {'scope': 'mysql', 'description': 'd'},
      );

      expect(result['success'], isFalse);
    });

    test('password 缺 lookupName 且缺 name 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.changeDatabasePassword(
        {'scope': 'mysql', 'password': 'p'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由两个改写 handler', () async {
      final d = await NativeChannelManager.instance.handleMethodCall(
        'updateDatabaseDescription',
        {'scope': 'mysql', 'description': 'd'},
      );
      final p = await NativeChannelManager.instance.handleMethodCall(
        'changeDatabasePassword',
        {'scope': 'mysql', 'password': 'p'},
      );

      expect(d['success'], isFalse);
      expect(p['success'], isFalse);
    });
  });
}
