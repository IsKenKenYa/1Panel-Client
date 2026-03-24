import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_compress.dart';

void main() {
  group('FileCompress 模型测试', () {
    group('CompressType 枚举', () {
      test('应该包含所有压缩类型', () {
        expect(CompressType.values, contains(CompressType.zip));
        expect(CompressType.values, contains(CompressType.tar));
        expect(CompressType.values, contains(CompressType.tarGz));
        expect(CompressType.values, contains(CompressType.sevenZ));
      });

      test('应该正确从字符串解析', () {
        expect(CompressType.fromString('zip'), equals(CompressType.zip));
        expect(CompressType.fromString('tar'), equals(CompressType.tar));
        expect(CompressType.fromString('tar.gz'), equals(CompressType.tarGz));
      });

      test('未知类型应返回默认值 zip', () {
        expect(CompressType.fromString('unknown'), equals(CompressType.zip));
      });

      test('应该正确获取显示名称', () {
        expect(CompressType.zip.displayName, equals('ZIP'));
        expect(CompressType.tar.displayName, equals('TAR'));
        expect(CompressType.tarGz.displayName, equals('TAR.GZ'));
      });
    });

    group('FileCompress', () {
      test('应该正确创建压缩请求', () {
        const compress = FileCompress(
          files: ['/file1.txt', '/file2.txt'],
          dst: '/archive/',
          name: 'archive',
          type: 'zip',
        );

        expect(compress.files, equals(['/file1.txt', '/file2.txt']));
        expect(compress.dst, equals('/archive/'));
        expect(compress.name, equals('archive'));
        expect(compress.type, equals('zip'));
      });

      test('应该正确序列化为 JSON', () {
        const compress = FileCompress(
          files: ['/file1.txt', '/file2.txt'],
          dst: '/archive/',
          name: 'archive',
          type: 'zip',
          secret: 'password',
          replace: true,
        );

        final json = compress.toJson();

        expect(json['files'], equals(['/file1.txt', '/file2.txt']));
        expect(json['dst'], equals('/archive/'));
        expect(json['name'], equals('archive'));
        expect(json['type'], equals('zip'));
        expect(json['secret'], equals('password'));
        expect(json['replace'], isTrue);
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {
          'files': ['/file1.txt', '/file2.txt'],
          'dst': '/archive/',
          'name': 'archive',
          'type': 'tar.gz',
        };

        final compress = FileCompress.fromJson(json);

        expect(compress.files.length, equals(2));
        expect(compress.dst, equals('/archive/'));
        expect(compress.name, equals('archive'));
        expect(compress.type, equals('tar.gz'));
      });

      test('应该支持相等性比较', () {
        const compress1 = FileCompress(
          files: ['/file.txt'],
          dst: '/archive/',
          name: 'archive',
          type: 'zip',
        );
        const compress2 = FileCompress(
          files: ['/file.txt'],
          dst: '/archive/',
          name: 'archive',
          type: 'zip',
        );

        expect(compress1, equals(compress2));
      });
    });

    group('FileExtract', () {
      test('应该正确创建解压请求', () {
        const extract = FileExtract(
          path: '/archive.zip',
          dst: '/extracted/',
          type: 'zip',
        );

        expect(extract.path, equals('/archive.zip'));
        expect(extract.dst, equals('/extracted/'));
        expect(extract.type, equals('zip'));
      });

      test('应该正确序列化为 JSON', () {
        const extract = FileExtract(
          path: '/archive.zip',
          dst: '/extracted/',
          type: 'zip',
          secret: 'password',
        );

        final json = extract.toJson();

        expect(json['path'], equals('/archive.zip'));
        expect(json['dst'], equals('/extracted/'));
        expect(json['type'], equals('zip'));
        expect(json['secret'], equals('password'));
      });

      test('应该正确从 JSON 反序列化', () {
        final json = {
          'path': '/archive.tar.gz',
          'dst': '/extracted/',
          'type': 'tar.gz',
        };

        final extract = FileExtract.fromJson(json);

        expect(extract.path, equals('/archive.tar.gz'));
        expect(extract.dst, equals('/extracted/'));
        expect(extract.type, equals('tar.gz'));
      });

      test('应该支持相等性比较', () {
        const extract1 = FileExtract(
          path: '/archive.zip',
          dst: '/extracted/',
          type: 'zip',
        );
        const extract2 = FileExtract(
          path: '/archive.zip',
          dst: '/extracted/',
          type: 'zip',
        );

        expect(extract1, equals(extract2));
      });
    });
  });
}
