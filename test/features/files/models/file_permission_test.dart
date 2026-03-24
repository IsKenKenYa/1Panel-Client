import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_permission.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';

void main() {
  group('FilePermission 模型测试', () {
    group('FileModeChange', () {
      test('应该正确创建 FileModeChange 实例', () {
        const modeChange = FileModeChange(
          path: '/test/file.txt',
          mode: 493,
          sub: true,
        );

        expect(modeChange.path, equals('/test/file.txt'));
        expect(modeChange.mode, equals(493));
        expect(modeChange.sub, isTrue);
      });

      test('应该正确序列化为 JSON', () {
        const modeChange = FileModeChange(
          path: '/test/file.txt',
          mode: 493,
          sub: true,
        );

        final json = modeChange.toJson();

        expect(json['path'], equals('/test/file.txt'));
        expect(json['mode'], equals(493));
        expect(json['sub'], isTrue);
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {
          'path': '/test/file.txt',
          'mode': 493,
          'sub': true,
        };

        final modeChange = FileModeChange.fromJson(json);

        expect(modeChange.path, equals('/test/file.txt'));
        expect(modeChange.mode, equals(493));
        expect(modeChange.sub, isTrue);
      });

      test('sub 字段应该可选', () {
        const modeChange = FileModeChange(
          path: '/test/file.txt',
          mode: 493,
        );

        final json = modeChange.toJson();

        expect(json.containsKey('sub'), isFalse);
      });

      test('应该支持相等性比较', () {
        const mode1 = FileModeChange(path: '/test/file.txt', mode: 493);
        const mode2 = FileModeChange(path: '/test/file.txt', mode: 493);
        const mode3 = FileModeChange(path: '/test/file.txt', mode: 755);

        expect(mode1, equals(mode2));
        expect(mode1, isNot(equals(mode3)));
      });
    });

    group('FileOwnerChange', () {
      test('应该正确创建 FileOwnerChange 实例', () {
        const ownerChange = FileOwnerChange(
          path: '/test/file.txt',
          user: 'root',
          group: 'root',
          sub: true,
        );

        expect(ownerChange.path, equals('/test/file.txt'));
        expect(ownerChange.user, equals('root'));
        expect(ownerChange.group, equals('root'));
        expect(ownerChange.sub, isTrue);
      });

      test('应该正确序列化为 JSON', () {
        const ownerChange = FileOwnerChange(
          path: '/test/file.txt',
          user: 'root',
          group: 'root',
        );

        final json = ownerChange.toJson();

        expect(json['path'], equals('/test/file.txt'));
        expect(json['user'], equals('root'));
        expect(json['group'], equals('root'));
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {
          'path': '/test/file.txt',
          'user': 'root',
          'group': 'root',
          'sub': true,
        };

        final ownerChange = FileOwnerChange.fromJson(json);

        expect(ownerChange.path, equals('/test/file.txt'));
        expect(ownerChange.user, equals('root'));
        expect(ownerChange.group, equals('root'));
        expect(ownerChange.sub, isTrue);
      });
    });

    group('FileUserGroup', () {
      test('应该正确创建实例', () {
        const userGroup = FileUserGroup(user: 'root', group: 'root');

        expect(userGroup.user, equals('root'));
        expect(userGroup.group, equals('root'));
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {'user': 'www-data', 'group': 'www-data'};

        final userGroup = FileUserGroup.fromJson(json);

        expect(userGroup.user, equals('www-data'));
        expect(userGroup.group, equals('www-data'));
      });
    });

    group('FileUserGroupResponse', () {
      test('应该正确创建实例', () {
        final response = FileUserGroupResponse(
          users: const [
            FileUserGroup(user: 'root', group: 'root'),
            FileUserGroup(user: 'www-data', group: 'www-data'),
          ],
          groups: ['root', 'www-data', 'nginx'],
        );

        expect(response.users, hasLength(2));
        expect(response.groups, hasLength(3));
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {
          'users': [
            {'user': 'root', 'group': 'root'},
            {'user': 'www-data', 'group': 'www-data'},
          ],
          'groups': ['root', 'www-data'],
        };

        final response = FileUserGroupResponse.fromJson(json);

        expect(response.users, hasLength(2));
        expect(response.users.first.user, equals('root'));
        expect(response.groups, equals(['root', 'www-data']));
      });
    });

    group('权限模式计算', () {
      test('应该正确计算 755 权限值', () {
        const mode = 493;
        expect(mode, equals(int.parse('755', radix: 8)));
      });

      test('应该正确计算 644 权限值', () {
        const mode = 420;
        expect(mode, equals(int.parse('644', radix: 8)));
      });

      test('应该正确计算 777 权限值', () {
        const mode = 511;
        expect(mode, equals(int.parse('777', radix: 8)));
      });

      test('应该正确计算 600 权限值', () {
        const mode = 384;
        expect(mode, equals(int.parse('600', radix: 8)));
      });
    });
  });

  group('FileInfo 权限字段测试', () {
    test('应该正确解析权限字符串', () {
      final json = {
        'name': 'test.txt',
        'path': '/test/test.txt',
        'size': 1024,
        'isDir': false,
        'modTime': '2024-01-01T00:00:00Z',
        'permission': '755',
        'user': 'root',
        'group': 'root',
      };

      final fileInfo = FileInfo.fromJson(json);

      expect(fileInfo.permission, equals('755'));
      expect(fileInfo.user, equals('root'));
      expect(fileInfo.group, equals('root'));
    });

    test('应该正确处理缺失的权限字段', () {
      final json = {
        'name': 'test.txt',
        'path': '/test/test.txt',
        'size': 1024,
        'isDir': false,
        'modTime': '2024-01-01T00:00:00Z',
      };

      final fileInfo = FileInfo.fromJson(json);

      expect(fileInfo.permission, isNull);
      expect(fileInfo.user, isNull);
      expect(fileInfo.group, isNull);
    });
  });
}
