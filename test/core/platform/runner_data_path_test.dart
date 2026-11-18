import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/runner_data_path.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  group('RunnerDataPath.resolveRunnerSupportDirectory', () {
    test('拼接 APPDATA 与 runner 公司/产品目录', () {
      final result = RunnerDataPath.resolveRunnerSupportDirectory(
        appDataDir: r'C:\Users\u\AppData\Roaming',
      );

      expect(result, r'C:\Users\u\AppData\Roaming\IsKenKenYa\1Panel Client');
    });

    test('APPDATA 缺失时返回 null', () {
      expect(RunnerDataPath.resolveRunnerSupportDirectory(appDataDir: null),
          isNull);
      expect(RunnerDataPath.resolveRunnerSupportDirectory(appDataDir: ''),
          isNull);
    });
  });

  group('RunnerAlignedPathProvider', () {
    test('getApplicationSupportPath 返回固定路径', () async {
      final provider = RunnerAlignedPathProvider(
        fallback: const _FakePathProvider(),
        supportPath: r'C:\x\1Panel Client',
      );

      expect(await provider.getApplicationSupportPath(),
          r'C:\x\1Panel Client');
    });

    test('alignAllPathProviders 覆盖 SharedPreferencesWindows 内部 pathProvider',
        () {
      final store = SharedPreferencesWindows();
      final original = store.pathProvider;

      RunnerDataPath.alignAllPathProviders(
        fallback: PathProviderPlatform.instance,
        supportPath: r'C:ligned',
        store: store,
      );

      expect(store.pathProvider.getApplicationSupportPath(),
          completion(r'C:ligned'));
      // 还原，避免污染其他测试
      store.pathProvider = original;
    });

    test('其余方法委托 fallback', () async {
      final fallback = const _FakePathProvider();
      final provider =
          RunnerAlignedPathProvider(fallback: fallback, supportPath: r'C:\x');

      expect(await provider.getTemporaryPath(), 'tmp');
      expect(identical(provider.getTemporaryPath, fallback.getTemporaryPath),
          isFalse);
    });

    test('getApplicationDocumentsPath 委托 fallback（Hive 共享契约）', () async {
      // hive_flutter 的 Hive.initFlutter 固定取文档目录（进程无关）。
      // 对齐实现必须保持委托，使引擎与 runner 解析到同一文档目录；
      // 若误返回 supportPath 会与 runner 侧 Hive 分叉。
      final provider = RunnerAlignedPathProvider(
        fallback: const _FakePathProvider(),
        supportPath: r'C:\support',
      );

      expect(
        await provider.getApplicationDocumentsPath(),
        r'C:\Users\u\Documents',
      );
    });
  });

  group('alignAllPathProviders 重复对齐', () {
    test('重复调用结果稳定，不产生包装链叠加', () async {
      final originalInstance = PathProviderPlatform.instance;
      final store = SharedPreferencesWindows();
      final originalStoreProvider = store.pathProvider;
      try {
        // 复刻 main() 若重复对齐的序列：第二次对齐会把第一次的
        // RunnerAlignedPathProvider 捕获为 fallback。
        RunnerDataPath.alignAllPathProviders(
          fallback: PathProviderPlatform.instance,
          supportPath: r'C:\one',
          store: store,
        );
        RunnerDataPath.alignAllPathProviders(
          fallback: PathProviderPlatform.instance,
          supportPath: r'C:\two',
          store: store,
        );

        expect(
          await PathProviderPlatform.instance.getApplicationSupportPath(),
          r'C:\two',
        );
        expect(
          await store.pathProvider.getApplicationSupportPath(),
          r'C:\two',
        );
      } finally {
        PathProviderPlatform.instance = originalInstance;
        store.pathProvider = originalStoreProvider;
      }
    });
  });
}

class _FakePathProvider implements PathProviderPlatform {
  const _FakePathProvider();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getTemporaryPath) {
      return Future<String?>.value('tmp');
    }
    if (invocation.memberName == #getApplicationDocumentsPath) {
      return Future<String?>.value(r'C:\Users\u\Documents');
    }
    return null;
  }
}
