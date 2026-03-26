import 'dio_client.dart';
import '../config/api_config.dart';
import '../../api/v2/app_v2.dart';
import '../../api/v2/auth_v2.dart';
import '../../api/v2/container_v2.dart';
import '../../api/v2/dashboard_v2.dart';
import '../../api/v2/database_v2.dart';
import '../../api/v2/file_v2.dart';
import '../../api/v2/firewall_v2.dart';
import '../../api/v2/host_v2.dart';
import '../../api/v2/logs_v2.dart';
import '../../api/v2/monitor_v2.dart';
import '../../api/v2/setting_v2.dart';
import '../../api/v2/terminal_v2.dart';
import '../../api/v2/update_v2.dart';
import '../../api/v2/website_v2.dart';
import '../../api/v2/docker_v2.dart';
import '../../api/v2/compose_v2.dart';

/// API客户端管理器
/// 用于管理多个服务器配置的API客户端实例
class ApiClientManager {
  static final ApiClientManager _instance = ApiClientManager._internal();
  final Map<String, DioClient> _clients = {};
  final Map<String, _ClientConfigMeta> _clientMeta = {};

  factory ApiClientManager() {
    return _instance;
  }

  static ApiClientManager get instance => _instance;

  ApiClientManager._internal();

  Future<ApiConfig> _getCurrentConfig() async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }
    return config;
  }

  /// 获取指定服务器的API客户端
  DioClient getClient(String serverId, String serverUrl, String apiKey,
      {bool ignoreTls = false}) {
    final nextMeta =
        _ClientConfigMeta(url: serverUrl, apiKey: apiKey, ignoreTls: ignoreTls);
    final currentMeta = _clientMeta[serverId];

    if (currentMeta == nextMeta && _clients.containsKey(serverId)) {
      return _clients[serverId]!;
    }

    final client = DioClient(
      baseUrl: serverUrl,
      apiKey: apiKey,
      ignoreTls: ignoreTls,
    );
    _clients[serverId] = client;
    _clientMeta[serverId] = nextMeta;
    return client;
  }

  Future<DioClient> getCurrentClient() async {
    final config = await _getCurrentConfig();
    return getClient(config.id, config.url, config.apiKey,
        ignoreTls: config.ignoreTls);
  }

  Future<AppV2Api> getAppApi() async {
    final client = await getCurrentClient();
    return AppV2Api(client);
  }

  Future<ContainerV2Api> getContainerApi() async {
    final client = await getCurrentClient();
    return ContainerV2Api(client);
  }

  Future<WebsiteV2Api> getWebsiteApi() async {
    final client = await getCurrentClient();
    return WebsiteV2Api(client);
  }

  Future<DashboardV2Api> getDashboardApi() async {
    final client = await getCurrentClient();
    return DashboardV2Api(client);
  }

  Future<HostV2Api> getHostApi() async {
    final client = await getCurrentClient();
    return HostV2Api(client);
  }

  Future<DatabaseV2Api> getDatabaseApi() async {
    final client = await getCurrentClient();
    return DatabaseV2Api(client);
  }

  Future<FirewallV2Api> getFirewallApi() async {
    final client = await getCurrentClient();
    return FirewallV2Api(client);
  }

  Future<MonitorV2Api> getMonitorApi() async {
    final client = await getCurrentClient();
    return MonitorV2Api(client);
  }

  Future<SettingV2Api> getSettingApi() async {
    final client = await getCurrentClient();
    return SettingV2Api(client);
  }

  Future<TerminalV2Api> getTerminalApi() async {
    final client = await getCurrentClient();
    return TerminalV2Api(client);
  }

  Future<LogsV2Api> getLogsApi() async {
    final client = await getCurrentClient();
    return LogsV2Api(client);
  }

  Future<UpdateV2Api> getUpdateApi() async {
    final client = await getCurrentClient();
    return UpdateV2Api(client);
  }

  Future<AuthV2Api> getAuthApi() async {
    final client = await getCurrentClient();
    return AuthV2Api(client);
  }

  Future<FileV2Api> getFileApi() async {
    final client = await getCurrentClient();
    return FileV2Api(client);
  }

  Future<DockerV2Api> getDockerApi() async {
    final client = await getCurrentClient();
    return DockerV2Api(client);
  }

  Future<ComposeV2Api> getComposeApi() async {
    final client = await getCurrentClient();
    return ComposeV2Api(client);
  }

  /// 移除指定服务器的API客户端
  void removeClient(String serverId) {
    _clients.remove(serverId);
    _clientMeta.remove(serverId);
  }

  /// 清除所有API客户端
  void clearAllClients() {
    _clients.clear();
    _clientMeta.clear();
  }
}

class _ClientConfigMeta {
  const _ClientConfigMeta({
    required this.url,
    required this.apiKey,
    this.ignoreTls = false,
  });

  final String url;
  final String apiKey;
  final bool ignoreTls;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ClientConfigMeta &&
        other.url == url &&
        other.apiKey == apiKey &&
        other.ignoreTls == ignoreTls;
  }

  @override
  int get hashCode => Object.hash(url, apiKey, ignoreTls);
}
