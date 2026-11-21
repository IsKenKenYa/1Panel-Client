import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 后台任务只持久保存服务器 ID，每次重新签名前校验任务的目标地址。
abstract final class OnePanelDownloadSource {
  static String _key(String taskId) => 'kenpanel_download_owner_$taskId';

  static Uri urlFor(ApiConfig config, String remotePath) {
    config.requireOnePanel();
    final base = Uri.parse(config.url);
    if (!{'http', 'https'}.contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasFragment ||
        base.hasQuery) {
      throw FormatException('服务器地址无法用于文件下载');
    }
    final path = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: '$path${ApiConstants.buildApiPath('/files/download')}',
      queryParameters: {'path': remotePath},
    );
  }

  static bool matches(ApiConfig config, Uri target) {
    final paths = target.queryParametersAll['path'];
    if (paths == null || paths.length != 1 || paths.single.isEmpty) return false;
    return target == urlFor(config, paths.single);
  }

  static Future<void> remember(String taskId, String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key(taskId), serverId)) {
      throw StateError('无法保存下载任务所属服务器');
    }
  }

  static Future<void> forget(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(taskId));
  }

  static Future<ApiConfig> owner(String taskId, Uri target) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key(taskId));
    if (id == null) throw StateError('无法确定下载任务所属服务器');
    final config = await ApiConfigManager.getConfig(id);
    if (!matches(config, target)) {
      throw StateError('服务器地址与下载任务不一致');
    }
    return config;
  }
}
