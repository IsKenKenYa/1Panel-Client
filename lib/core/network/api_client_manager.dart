import '../../api/v2/app_v2.dart';
import '../../api/v2/auth_v2.dart';
import '../../api/v2/backup_account_v2.dart';
import '../../api/v2/command_v2.dart';
import '../../api/v2/compose_v2.dart';
import '../../api/v2/container_v2.dart';
import '../../api/v2/cronjob_v2.dart';
import '../../api/v2/dashboard_v2.dart';
import '../../api/v2/database_v2.dart';
import '../../api/v2/disk_management_v2.dart';
import '../../api/v2/docker_v2.dart';
import '../../api/v2/file_v2.dart';
import '../../api/v2/firewall_v2.dart';
import '../../api/v2/host_v2.dart';
import '../../api/v2/host_tool_v2.dart';
import '../../api/v2/logs_v2.dart';
import '../../api/v2/monitor_v2.dart';
import '../../api/v2/openresty_v2.dart';
import '../../api/v2/process_v2.dart';
import '../../api/v2/runtime_v2.dart';
import '../../api/v2/script_library_v2.dart';
import '../../api/v2/setting_v2.dart';
import '../../api/v2/ssh_v2.dart';
import '../../api/v2/ssl_v2.dart';
import '../../api/v2/system_group_v2.dart';
import '../../api/v2/task_log_v2.dart';
import '../../api/v2/terminal_v2.dart';
import '../../api/v2/toolbox_v2.dart';
import '../../api/v2/update_v2.dart';
import '../../api/v2/website_v2.dart';
import '../../api/v2/ai_v2.dart';
import '../config/api_config.dart';
import 'dio_client.dart';

class ApiClientManager {
  ApiClientManager._internal();

  static final ApiClientManager _instance = ApiClientManager._internal();

  factory ApiClientManager() => _instance;

  static ApiClientManager get instance => _instance;

  final Map<String, DioClient> _clients = <String, DioClient>{};
  final Map<String, _ClientConfigMeta> _clientMeta =
      <String, _ClientConfigMeta>{};

  Future<ApiConfig> _getCurrentConfig() async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }
    return config;
  }

  DioClient getClient(String serverId, String serverUrl, String apiKey) {
    final nextMeta = _ClientConfigMeta(url: serverUrl, apiKey: apiKey);
    final currentMeta = _clientMeta[serverId];

    if (currentMeta == nextMeta && _clients.containsKey(serverId)) {
      return _clients[serverId]!;
    }

    final client = DioClient(
      baseUrl: serverUrl,
      apiKey: apiKey,
    );
    _clients[serverId] = client;
    _clientMeta[serverId] = nextMeta;
    return client;
  }

  Future<DioClient> getCurrentClient() async {
    final config = await _getCurrentConfig();
    return getClient(config.id, config.url, config.apiKey);
  }

  Future<AppV2Api> getAppApi() async => AppV2Api(await getCurrentClient());

  Future<AuthV2Api> getAuthApi() async => AuthV2Api(await getCurrentClient());

  Future<BackupAccountV2Api> getBackupAccountApi() async =>
      BackupAccountV2Api(await getCurrentClient());

  Future<CommandV2Api> getCommandApi() async =>
      CommandV2Api(await getCurrentClient());

  Future<ComposeV2Api> getComposeApi() async =>
      ComposeV2Api(await getCurrentClient());

  Future<ContainerV2Api> getContainerApi() async =>
      ContainerV2Api(await getCurrentClient());

  Future<CronjobV2Api> getCronjobApi() async =>
      CronjobV2Api(await getCurrentClient());

  Future<DashboardV2Api> getDashboardApi() async =>
      DashboardV2Api(await getCurrentClient());

  Future<DatabaseV2Api> getDatabaseApi() async =>
      DatabaseV2Api(await getCurrentClient());

  Future<DiskManagementV2Api> getDiskManagementApi() async =>
      DiskManagementV2Api(await getCurrentClient());

  Future<DockerV2Api> getDockerApi() async =>
      DockerV2Api(await getCurrentClient());

  Future<FileV2Api> getFileApi() async => FileV2Api(await getCurrentClient());

  Future<FirewallV2Api> getFirewallApi() async =>
      FirewallV2Api(await getCurrentClient());

  Future<HostV2Api> getHostApi() async => HostV2Api(await getCurrentClient());

  Future<HostToolV2Api> getHostToolApi() async =>
      HostToolV2Api(await getCurrentClient());

  Future<LogsV2Api> getLogsApi() async => LogsV2Api(await getCurrentClient());

  Future<MonitorV2Api> getMonitorApi() async =>
      MonitorV2Api(await getCurrentClient());

  Future<OpenRestyV2Api> getOpenRestyApi() async =>
      OpenRestyV2Api(await getCurrentClient());

  Future<ProcessV2Api> getProcessApi() async =>
      ProcessV2Api(await getCurrentClient());

  Future<ScriptLibraryV2Api> getScriptLibraryApi() async =>
      ScriptLibraryV2Api(await getCurrentClient());

  Future<RuntimeV2Api> getRuntimeApi() async =>
      RuntimeV2Api(await getCurrentClient());

  Future<SettingV2Api> getSettingApi() async =>
      SettingV2Api(await getCurrentClient());

  Future<SshV2Api> getSshApi() async => SshV2Api(await getCurrentClient());

  Future<SSLV2Api> getSslApi() async => SSLV2Api(await getCurrentClient());

  Future<SystemGroupV2Api> getSystemGroupApi() async =>
      SystemGroupV2Api(await getCurrentClient());

  Future<TaskLogV2Api> getTaskLogApi() async =>
      TaskLogV2Api(await getCurrentClient());

  Future<TerminalV2Api> getTerminalApi() async =>
      TerminalV2Api(await getCurrentClient());

  Future<ToolboxV2Api> getToolboxApi() async =>
      ToolboxV2Api(await getCurrentClient());

  Future<UpdateV2Api> getUpdateApi() async =>
      UpdateV2Api(await getCurrentClient());

  Future<WebsiteV2Api> getWebsiteApi() async =>
      WebsiteV2Api(await getCurrentClient());

  Future<AIV2Api> getAiApi() async {
    final client = await getCurrentClient();
    return AIV2Api(client);
  }

  void removeClient(String serverId) {
    _clients.remove(serverId);
    _clientMeta.remove(serverId);
  }

  void clearAllClients() {
    _clients.clear();
    _clientMeta.clear();
  }
}

class _ClientConfigMeta {
  const _ClientConfigMeta({
    required this.url,
    required this.apiKey,
  });

  final String url;
  final String apiKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ClientConfigMeta &&
        other.url == url &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode => Object.hash(url, apiKey);
}
