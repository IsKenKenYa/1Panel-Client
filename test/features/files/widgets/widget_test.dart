import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';

void main() {
  group('Widget 页面测试', () {
    group('FileInfo Widget 测试', () {
      testWidgets('应该正确显示文件信息', (WidgetTester tester) async {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 1024,
          type: 'file',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                title: Text(file.name),
                subtitle: Text('${file.size} bytes'),
              ),
            ),
          ),
        );

        expect(find.text('test.txt'), findsOneWidget);
        expect(find.text('1024 bytes'), findsOneWidget);
      });

      testWidgets('应该正确显示目录信息', (WidgetTester tester) async {
        final dir = FileInfo(
          name: 'mydir',
          path: '/mydir',
          size: 0,
          type: 'dir',
          isDir: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                leading:
                    Icon(dir.isDir ? Icons.folder : Icons.insert_drive_file),
                title: Text(dir.name),
              ),
            ),
          ),
        );

        expect(find.text('mydir'), findsOneWidget);
        expect(find.byIcon(Icons.folder), findsOneWidget);
      });

      testWidgets('应该正确显示文件权限信息', (WidgetTester tester) async {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 1024,
          type: 'file',
          permission: 'rw-r--r--',
          user: 'root',
          group: 'root',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Permission: ${file.permission}'),
                  Text('Owner: ${file.user}:${file.group}'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Permission: rw-r--r--'), findsOneWidget);
        expect(find.text('Owner: root:root'), findsOneWidget);
      });

      testWidgets('应该正确显示符号链接', (WidgetTester tester) async {
        final link = FileInfo(
          name: 'link',
          path: '/link',
          size: 0,
          type: 'file',
          isSymlink: true,
          linkTarget: '/target/file.txt',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                leading: const Icon(Icons.link),
                title: Text(link.name),
                subtitle: Text('-> ${link.linkTarget}'),
              ),
            ),
          ),
        );

        expect(find.text('link'), findsOneWidget);
        expect(find.text('-> /target/file.txt'), findsOneWidget);
      });
    });

    group('文件大小格式化测试', () {
      test('应该正确格式化字节', () {
        expect(_formatFileSize(500), equals('500 B'));
      });

      test('应该正确格式化 KB', () {
        expect(_formatFileSize(1024), equals('1.00 KB'));
        expect(_formatFileSize((1024 * 1.5).toInt()), equals('1.50 KB'));
      });

      test('应该正确格式化 MB', () {
        expect(_formatFileSize(1024 * 1024), equals('1.00 MB'));
        expect(_formatFileSize((1024 * 1024 * 1.5).toInt()), equals('1.50 MB'));
      });

      test('应该正确格式化 GB', () {
        expect(_formatFileSize(1024 * 1024 * 1024), equals('1.00 GB'));
        expect(_formatFileSize((1024 * 1024 * 1024 * 1.5).toInt()),
            equals('1.50 GB'));
      });

      test('应该正确格式化 TB', () {
        expect(_formatFileSize((1024.0 * 1024 * 1024 * 1024).toInt()),
            equals('1.00 TB'));
      });
    });

    group('FileInfo 模型测试', () {
      test('应该正确创建 FileInfo', () {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 1024,
          type: 'file',
        );

        expect(file.name, equals('test.txt'));
        expect(file.path, equals('/test.txt'));
        expect(file.size, equals(1024));
        expect(file.type, equals('file'));
        expect(file.isDir, isFalse);
      });

      test('应该正确从 JSON 创建 FileInfo', () {
        final json = {
          'name': 'test.txt',
          'path': '/test.txt',
          'size': 1024,
          'type': 'file',
          'isDir': false,
        };

        final file = FileInfo.fromJson(json);

        expect(file.name, equals('test.txt'));
        expect(file.path, equals('/test.txt'));
        expect(file.size, equals(1024));
        expect(file.type, equals('file'));
      });

      test('应该正确序列化 FileInfo 到 JSON', () {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 1024,
          type: 'file',
        );

        final json = file.toJson();

        expect(json['name'], equals('test.txt'));
        expect(json['path'], equals('/test.txt'));
        expect(json['size'], equals(1024));
        expect(json['type'], equals('file'));
      });

      test('应该正确判断目录', () {
        final dir = FileInfo(
          name: 'mydir',
          path: '/mydir',
          size: 0,
          type: 'dir',
          isDir: true,
        );

        expect(dir.isDir, isTrue);
      });

      test('应该正确处理符号链接', () {
        final link = FileInfo(
          name: 'link',
          path: '/link',
          size: 0,
          type: 'file',
          isSymlink: true,
          linkTarget: '/target',
        );

        expect(link.isSymlink, isTrue);
        expect(link.linkTarget, equals('/target'));
      });

      test('应该正确处理子目录', () {
        final dir = FileInfo(
          name: 'parent',
          path: '/parent',
          size: 0,
          type: 'dir',
          isDir: true,
          children: [
            FileInfo(
                name: 'child1.txt',
                path: '/parent/child1.txt',
                size: 100,
                type: 'file'),
            FileInfo(
                name: 'child2.txt',
                path: '/parent/child2.txt',
                size: 200,
                type: 'file'),
          ],
        );

        expect(dir.children, isNotNull);
        expect(dir.children!.length, equals(2));
        expect(dir.children![0].name, equals('child1.txt'));
      });

      test('应该正确处理隐藏文件', () {
        final hiddenFile = FileInfo(
          name: '.hidden',
          path: '/.hidden',
          size: 100,
          type: 'file',
          isHidden: true,
        );

        expect(hiddenFile.isHidden, isTrue);
      });

      test('应该正确处理收藏文件', () {
        final favoriteFile = FileInfo(
          name: 'favorite.txt',
          path: '/favorite.txt',
          size: 100,
          type: 'file',
          favoriteID: 123,
        );

        expect(favoriteFile.favoriteID, equals(123));
      });
    });

    group('文件路径处理测试', () {
      test('应该正确获取文件扩展名', () {
        final file = FileInfo(
          name: 'document.pdf',
          path: '/documents/document.pdf',
          size: 1024,
          type: 'file',
          extension: 'pdf',
        );

        expect(file.extension, equals('pdf'));
      });

      test('应该正确处理无扩展名文件', () {
        final file = FileInfo(
          name: 'README',
          path: '/README',
          size: 100,
          type: 'file',
        );

        expect(file.extension, isNull);
      });

      test('应该正确处理多级路径', () {
        final file = FileInfo(
          name: 'file.txt',
          path: '/a/b/c/d/file.txt',
          size: 100,
          type: 'file',
        );

        expect(file.path, equals('/a/b/c/d/file.txt'));
        expect(file.name, equals('file.txt'));
      });
    });

    group('文件时间属性测试', () {
      test('应该正确处理修改时间', () {
        final modifiedAt = DateTime(2024, 1, 15, 10, 30);
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 100,
          type: 'file',
          modifiedAt: modifiedAt,
        );

        expect(file.modifiedAt, equals(modifiedAt));
      });

      test('应该正确处理创建时间', () {
        final createdAt = DateTime(2024, 1, 10, 8, 0);
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 100,
          type: 'file',
          createdAt: createdAt,
        );

        expect(file.createdAt, equals(createdAt));
      });

      test('应该正确处理空时间', () {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 100,
          type: 'file',
        );

        expect(file.modifiedAt, isNull);
        expect(file.createdAt, isNull);
      });
    });

    group('文件权限属性测试', () {
      test('应该正确处理权限字符串', () {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 100,
          type: 'file',
          permission: 'rwxr-xr-x',
        );

        expect(file.permission, equals('rwxr-xr-x'));
      });

      test('应该正确处理用户和组', () {
        final file = FileInfo(
          name: 'test.txt',
          path: '/test.txt',
          size: 100,
          type: 'file',
          user: 'admin',
          group: 'staff',
        );

        expect(file.user, equals('admin'));
        expect(file.group, equals('staff'));
      });
    });

    group('文件 MIME 类型测试', () {
      test('应该正确处理 MIME 类型', () {
        final file = FileInfo(
          name: 'document.pdf',
          path: '/document.pdf',
          size: 1024,
          type: 'file',
          mimeType: 'application/pdf',
        );

        expect(file.mimeType, equals('application/pdf'));
      });

      test('应该正确处理空 MIME 类型', () {
        final file = FileInfo(
          name: 'unknown',
          path: '/unknown',
          size: 100,
          type: 'file',
        );

        expect(file.mimeType, isNull);
      });
    });
  });
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else if (bytes < 1024 * 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } else {
    return '${(bytes / (1024.0 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
  }
}
