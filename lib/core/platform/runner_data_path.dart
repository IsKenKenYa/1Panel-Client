import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

/// WinUI3 原生宿主(headless 引擎)与 Flutter runner 的数据目录对齐。
///
/// headless 引擎寄生在 OnePanelNativeHost.exe 进程内，path_provider 按该 exe
/// 的 VERSIONINFO 派生应用支持目录，与 Flutter runner（IsKenKenYa\1Panel
/// Client）不一致，导致服务器配置等数据读不到。此处在 host 激活时把
/// PathProviderPlatform 的支持目录显式对齐到 runner 目录——常量与
/// windows/runner/render_mode_bootstrap.cpp 的 kCompanyName/kProductName、
/// windows/runner/Runner.rc 的 VERSIONINFO 以及 OnePanelNativeHost.csproj
/// 的 Company/Product 同源，修改时必须四处同步。
///
/// 数据落点与持久化保证（全部位于当前用户 profile 下，卸载/重装均不丢）：
/// - SharedPreferences（服务器配置 shared_preferences.json）：对齐后落在
///   `%APPDATA%\IsKenKenYa\1Panel Client`。
/// - flutter_secure_storage（API Key，flutter_secure_storage_windows 4.x 的
///   DpapiJsonFileMapStorage 主存储）：经 getApplicationSupportDirectory() →
///   PathProviderPlatform.instance，同样被本对齐覆盖，落同上目录的
///   flutter_secure_storage.dat，双进程共享。插件 C++ 侧仅"旧版遗留数据
///   迁移读取"仍按宿主 exe VERSIONINFO 派生（.NET 程序集版本资源为
///   000004b0 语言段，插件只查 040904e4/040904b0，引擎侧回落
///   placeholder_company\placeholder_product）；该路径无法从 Dart 覆盖，
///   但只影响旧版插件历史数据在引擎进程内的首次迁移读取，新写入恒落主存储。
/// - Hive（Hive.initFlutter）：hive_flutter 固定使用"文档"目录
///   （FOLDERID_Documents，进程无关）。本类对 getApplicationDocumentsPath
///   保持委托 fallback，正是为了让引擎与 runner 解析到同一文档目录、共享
///   同一 Hive 库；不得改为支持目录，否则与 runner 侧分叉。
///
/// 降级行为：APPDATA 缺失时 resolveRunnerSupportDirectory 返回 null，
/// main() 跳过对齐并静默回落引擎默认路径（按宿主 exe 派生，本机为
/// `%APPDATA%\OnePanelNativeHost`），此时引擎与 runner 数据互不可见。
class RunnerDataPath {
  const RunnerDataPath._();

  static const String _companyName = 'IsKenKenYa';
  static const String _productName = '1Panel Client';

  /// 解析 Flutter runner 的应用支持目录；[appDataDir] 缺失时返回 null。
  static String? resolveRunnerSupportDirectory({String? appDataDir}) {
    if (appDataDir == null || appDataDir.isEmpty) {
      return null;
    }
    return [
      appDataDir,
      _companyName,
      _productName,
    ].join(Platform.pathSeparator);
  }

  /// 把所有已知的路径提供方对齐到 [supportPath]：
  /// - PathProviderPlatform.instance（path_provider/Hive 等消费）
  /// - SharedPreferencesWindows.pathProvider（其内部直接实例化，须单独覆盖）
  static void alignAllPathProviders({
    required PathProviderPlatform fallback,
    required String supportPath,
    SharedPreferencesStorePlatform? store,
  }) {
    PathProviderPlatform.instance = RunnerAlignedPathProvider(
      fallback: fallback,
      supportPath: supportPath,
    );
    final target = store ?? SharedPreferencesStorePlatform.instance;
    if (target is SharedPreferencesWindows) {
      // The field is the package's only injection seam for the support path
      // (annotated visible-for-testing upstream); required for host alignment.
      // ignore: invalid_use_of_visible_for_testing_member
      target.pathProvider = _FixedSupportPathWindows(supportPath);
    }
  }
}

/// 仅覆盖应用支持目录，其余路径查询委托原有实现。
/// PlatformInterface 约定必须 extends（implements 会被运行时防护拒绝），
/// 未覆盖的成员经 noSuchMethod 转发 fallback。
class RunnerAlignedPathProvider extends PathProviderPlatform {
  RunnerAlignedPathProvider({
    required PathProviderPlatform fallback,
    required String supportPath,
  })  : _fallback = fallback,
        _supportPath = supportPath;

  final PathProviderPlatform _fallback;
  final String _supportPath;

  // base 的各路径方法有默认实现（抛 UnimplementedError），须逐个转发。
  @override
  Future<String?> getApplicationSupportPath() async => _supportPath;

  @override
  Future<String?> getTemporaryPath() => _fallback.getTemporaryPath();

  @override
  Future<String?> getLibraryPath() => _fallback.getLibraryPath();

  @override
  Future<String?> getApplicationDocumentsPath() =>
      _fallback.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() =>
      _fallback.getApplicationCachePath();

  @override
  Future<String?> getExternalStoragePath() =>
      _fallback.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() =>
      _fallback.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      _fallback.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => _fallback.getDownloadsPath();
}

class _FixedSupportPathWindows extends PathProviderWindows {
  _FixedSupportPathWindows(this._supportPath);

  final String _supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => _supportPath;
}
