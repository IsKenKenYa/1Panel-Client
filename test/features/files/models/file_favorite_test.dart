import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file/file_favorite.dart';

void main() {
  group('FileFavorite 模型测试', () {
    group('FileFavorite', () {
      test('应该正确创建收藏项', () {
        const favorite = FileFavorite(
          path: '/favorite/path',
          name: 'My Favorite',
          description: '重要文件夹',
        );

        expect(favorite.path, equals('/favorite/path'));
        expect(favorite.name, equals('My Favorite'));
        expect(favorite.description, equals('重要文件夹'));
      });

      test('应该正确从 JSON 解析', () {
        final json = {
          'path': '/favorite/file.txt',
          'name': 'file.txt',
          'description': '重要文件',
        };

        final favorite = FileFavorite.fromJson(json);

        expect(favorite.path, equals('/favorite/file.txt'));
        expect(favorite.name, equals('file.txt'));
        expect(favorite.description, equals('重要文件'));
      });

      test('应该正确序列化为 JSON', () {
        const favorite = FileFavorite(
          path: '/favorite/path',
          name: 'My Favorite',
        );

        final json = favorite.toJson();

        expect(json['path'], equals('/favorite/path'));
        expect(json['name'], equals('My Favorite'));
      });

      test('应该支持相等性比较', () {
        const fav1 = FileFavorite(
          path: '/path',
          name: 'name',
        );

        const fav2 = FileFavorite(
          path: '/path',
          name: 'name',
        );

        expect(fav1, equals(fav2));
      });

      test('name 和 description 应该可选', () {
        const favorite = FileFavorite(path: '/path');

        expect(favorite.path, equals('/path'));
        expect(favorite.name, isNull);
        expect(favorite.description, isNull);
      });
    });

    group('FileUnfavorite', () {
      test('应该正确创建取消收藏请求', () {
        const unfavorite = FileUnfavorite(path: '/path/to/unfavorite');

        expect(unfavorite.path, equals('/path/to/unfavorite'));
      });

      test('应该正确序列化为 JSON', () {
        const unfavorite = FileUnfavorite(path: '/path/to/unfavorite');

        final json = unfavorite.toJson();

        expect(json['path'], equals('/path/to/unfavorite'));
      });

      test('应该正确从 JSON 解析', () {
        final json = {'path': '/path/to/unfavorite'};

        final unfavorite = FileUnfavorite.fromJson(json);

        expect(unfavorite.path, equals('/path/to/unfavorite'));
      });

      test('应该支持相等性比较', () {
        const unfav1 = FileUnfavorite(path: '/path');
        const unfav2 = FileUnfavorite(path: '/path');

        expect(unfav1, equals(unfav2));
      });
    });
  });
}
