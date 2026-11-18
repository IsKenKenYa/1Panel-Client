import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// B2 文件管理深度通道契约测试。
/// 契约单一事实源：docs/development/modules/b2_files_channel_contract.md。
/// 仿 native_channel_database_ops_test.dart：必填缺失快速失败，不发网络请求。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('B2 写 handler 必填缺失快速失败（不发网络请求）', () {
    test('createFileHandler 缺 path 返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.createFileHandler({'path': ''});

      expect(result['success'], isFalse);
      expect(result['error'], contains('path is required'));
    });

    test('renameFileHandler 缺 oldName/newName 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.renameFileHandler({});

      expect(result['success'], isFalse);
      expect(result['error'], contains('oldName and newName are required'));
    });

    test('moveFilesHandler 缺 newPath 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.moveFilesHandler({
        'oldPaths': <String>['/opt/a.txt'],
        'newPath': '',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('oldPaths and newPath are required'));
    });

    test('moveFilesHandler 缺 oldPaths 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.moveFilesHandler({
        'newPath': '/opt',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('oldPaths and newPath are required'));
    });

    test('compressFilesHandler 缺 files 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.compressFilesHandler({
        'files': <String>[],
        'dst': '/opt',
        'name': 'bundle',
        'type': 'zip',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('files is required'));
    });

    test('decompressFileHandler 缺 dst/type 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.decompressFileHandler({
        'path': '/opt/bundle.zip',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('path, dst and type are required'));
    });

    test('changeFileModeHandler 缺 mode 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.changeFileModeHandler({
        'path': '/opt/a.txt',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('path and mode are required'));
    });

    test('changeFileOwnerHandler 缺 user/group 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.changeFileOwnerHandler({
        'path': '/opt/a.txt',
        'user': 'root',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('path, user and group are required'));
    });

    test('saveFileContentHandler 缺 content 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.saveFileContentHandler({
        'path': '/opt/a.txt',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('path and content are required'));
    });

    test('addFavoriteHandler 缺 path 返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.addFavoriteHandler({'path': ''});

      expect(result['success'], isFalse);
      expect(result['error'], contains('path is required'));
    });

    test('removeFavoriteHandler 缺 id 返回失败结构', () async {
      final result =
          await NativeChannelWriteHandlers.removeFavoriteHandler({'id': null});

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });

    test('wgetDownloadHandler 缺 url 返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.wgetDownloadHandler({
        'url': '',
        'path': '/opt/downloads',
        'name': 'pkg.tar.gz',
      });

      expect(result['success'], isFalse);
      expect(result['error'], contains('url, path and name are required'));
    });
  });

  group('B2 dispatch 路由', () {
    test("handleMethodCall('renameFileHandler', {}) 返回失败结构", () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'renameFileHandler',
        {},
      );

      expect(result['success'], isFalse);
      expect(result.containsKey('error'), isTrue);
    });

    test("handleMethodCall('createFileHandler', {}) 返回失败结构", () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createFileHandler',
        {},
      );

      expect(result['success'], isFalse);
      expect(result.containsKey('error'), isTrue);
    });
  });

  group('B2 读 handler 空值惯例', () {
    test('getFileContentHandler 缺 path 返回空 map（不发网络请求）', () async {
      final result = await NativeChannelReadHandlers.getFileContentHandler({});

      expect(result, isEmpty);
    });

    test('getFavoritesHandler 无服务器配置时返回空列表', () async {
      final result = await NativeChannelReadHandlers.getFavoritesHandler({});

      // 无有效服务器时底层失败，handler 必须返回空列表而非抛出。
      expect(result, isEmpty);
    });
  });
}
