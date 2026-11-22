import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = AppPreferencesService();

  group('AppPreferencesService - file picker toggle', () {
    tearDown(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('default for new user is true (picker enabled)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final value = await service.loadUseFilePickerForFileOperations();
      expect(value, isTrue);
    });

    test('saving and reading new key works', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await service.saveUseFilePickerForFileOperations(false);
      final value = await service.loadUseFilePickerForFileOperations();
      expect(value, isFalse);
    });
  });

  group('AppPreferencesService - file save sub directory', () {
    tearDown(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('default sub directory is "KenPanel" when unset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final value = await service.loadFileSaveSubDirectoryName();
      expect(value, AppPreferencesService.defaultFileSaveSubDirectoryName);
      expect(value, 'KenPanel');
    });

    test('saving and reading custom name works', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await service.saveFileSaveSubDirectoryName('MyExports');
      final value = await service.loadFileSaveSubDirectoryName();
      expect(value, 'MyExports');
    });

    test('empty string is persisted and returned as empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await service.saveFileSaveSubDirectoryName('');
      final value = await service.loadFileSaveSubDirectoryName();
      expect(value, '');
    });
  });

  group('AppPreferencesService - 文件目录记忆', () {
    tearDown(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('未保存过时返回空映射', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final paths = await service.loadFileLastPaths();
      expect(paths, isEmpty);
    });

    test('多个服务器的目录可以读写', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await service.saveFileLastPaths(<String, String>{
        'server-a': '/opt',
        'server-b': '/var/log',
      });

      final paths = await service.loadFileLastPaths();
      expect(paths['server-a'], '/opt');
      expect(paths['server-b'], '/var/log');
    });

    test('覆盖写入后只保留最新映射', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await service.saveFileLastPaths(<String, String>{'server-a': '/opt'});
      await service.saveFileLastPaths(<String, String>{'server-a': '/etc'});

      final paths = await service.loadFileLastPaths();
      expect(paths['server-a'], '/etc');
    });

    test('存储内容损坏时返回空映射', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_file_last_path_by_server': 'not-json',
      });
      final paths = await service.loadFileLastPaths();
      expect(paths, isEmpty);
    });
  });
}
