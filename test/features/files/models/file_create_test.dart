import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_create.dart';

void main() {
  group('FileCreate 模型测试', () {
    test('应支持值相等性比较', () {
      expect(
        const FileCreate(path: 'path'),
        const FileCreate(path: 'path'),
      );
    });

    test('Props 应该正确', () {
      const fileCreate = FileCreate(
        path: 'path',
        content: 'content',
        isDir: true,
        permission: 'permission',
        isLink: true,
        linkPath: 'linkPath',
        isSymlink: true,
        sub: true,
        mode: 777,
      );
      expect(
        fileCreate.props,
        equals([
          'path',
          'content',
          true,
          'permission',
          true,
          'linkPath',
          true,
          true,
          777,
        ]),
      );
    });

    test('fromJson 应该返回正确的对象', () {
      final json = {
        'path': 'path',
        'content': 'content',
        'isDir': true,
        'permission': 'permission',
        'isLink': true,
        'linkPath': 'linkPath',
        'isSymlink': true,
        'sub': true,
        'mode': 777,
      };
      expect(
        FileCreate.fromJson(json),
        const FileCreate(
          path: 'path',
          content: 'content',
          isDir: true,
          permission: 'permission',
          isLink: true,
          linkPath: 'linkPath',
          isSymlink: true,
          sub: true,
          mode: 777,
        ),
      );
    });

    test('toJson 应该返回正确的 Map', () {
      const fileCreate = FileCreate(
        path: 'path',
        content: 'content',
        isDir: true,
        permission: 'permission',
        isLink: true,
        linkPath: 'linkPath',
        isSymlink: true,
        sub: true,
        mode: 777,
      );
      expect(
        fileCreate.toJson(),
        equals({
          'path': 'path',
          'content': 'content',
          'isDir': true,
          'permission': 'permission',
          'isLink': true,
          'linkPath': 'linkPath',
          'isSymlink': true,
          'sub': true,
          'mode': 777,
        }),
      );
    });
  });
}
