import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../../api/v2/api_response_parser.dart';
import '../../api/v2/website_v2.dart';
import '../../data/models/ai/agent_account_model_pool_models.dart';
import '../../data/models/alert_models.dart';
import '../../data/models/ai/agent_account_models.dart';
import '../../data/models/ai/agent_core_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_models.dart';
import '../../data/models/mcp_models.dart';
import '../../features/ai/ai_repository.dart';
import '../../features/apps/app_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/containers/container_service.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../features/dashboard/services/dashboard_service.dart';
import '../../features/databases/databases_service.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/firewall/firewall_service.dart';
import '../../features/firewall/firewall_v2_service.dart';
import 'native_firewall_payloads.dart';
import '../../features/logs/services/logs_service.dart';
import '../../data/models/logs_models.dart';
import '../../data/models/process_models.dart';
import '../../data/models/task_log_models.dart';
import '../../features/openresty/services/openresty_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../../data/models/script_library_models.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/websites/services/website_certificate_service.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/toolbox/services/toolbox_device_service.dart';
import '../../features/toolbox/services/toolbox_disk_service.dart';
import '../../features/runtimes/services/runtime_service.dart';
import '../../features/host_assets/services/host_asset_service.dart';
import '../../data/models/host_asset_models.dart';
import '../../features/monitoring/monitoring_service.dart';
import 'native_monitoring_payloads.dart';
import '../../features/alert/alert_service.dart';
import 'native_alert_payloads.dart';
import '../../features/ai/model_downloader_service.dart';
import 'native_model_downloader_payloads.dart';
import '../../features/vm/vm_service.dart';
import 'native_vm_payloads.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../data/models/app_models.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/cronjob_record_models.dart';
import '../../data/models/database_models.dart';
import '../../data/repositories/database_repository.dart';
import '../../data/repositories/website_repository.dart';
import '../services/app_preferences_service.dart';
import '../services/logger/logger_service.dart';
import 'native_server_config.dart';

/// B1 网站配置中心读通道使用的网站 V2 API（按需构造）。
Future<WebsiteV2Api> _websiteApi() async =>
    WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());

/// 所有 Native Channel 读操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelReadHandlers {
  // ── 原有 handlers ────────────────────────────────────────────────────────

  static Future<dynamic> getServers(dynamic arguments) async {
    final repository = ServerRepository();
    // 原生轨道的服务器列表直接展示 CPU 与内存，必须带指标返回。
    final servers = await repository.loadServerCards(withMetrics: true);
    return servers
        .map((s) => {
              ...describeNativeServer(s.config, isCurrent: s.isCurrent),
              'cpu': s.metrics.cpuPercent,
              'memory': s.metrics.memoryPercent,
              'reachable': s.metrics.isReachable,
              'latencyMs': s.metrics.latencyMs,
            })
        .toList();
  }

  static Future<Map<String, Object?>?> getCurrentServer() async {
    final config = await ApiConfigManager.getCurrentServerMetadata();
    return config == null ? null : describeNativeServer(config, isCurrent: true);
  }

  static Future<dynamic> getFiles(dynamic arguments) async {
    final service = FileBrowserService();
    final path = arguments?['path'] as String? ?? '/';
    final files = await service.getFiles(path: path);
    return files
        .map((f) => {
              'name': f.name,
              'path': f.path,
              'isDir': f.isDir,
              'size': f.size,
              'modTime': f.modifiedAt?.millisecondsSinceEpoch ?? 0,
            })
        .toList();
  }

  static Future<dynamic> getApps(dynamic arguments) async {
    final service = AppService();
    // `/apps/installed/list` 只返回 {id, key, name}，没有状态与版本；
    // 列表页需要完整信息，走 `/apps/installed/search`。
    final page = await service.searchInstalledApps(
      AppInstalledSearchRequest(page: 1, pageSize: 100),
    );
    return page.items
        .map((a) => {
              'name': a.appName ?? a.name ?? '',
              'status': a.status ?? '',
              'version': a.version ?? '',
              'icon': a.icon ?? '',
              'appId': a.appId,
              'installId': a.id,
            })
        .toList();
  }

  /// 已安装应用详情。参数：`{installId: int}`。
  /// 上游返回 `HttpPort`（首字母大写），这里同时回传规范化后的 `httpPort`。
  static Future<dynamic> getAppInstallInfo(dynamic arguments) async {
    final installId = arguments['installId']?.toString() ?? '';
    if (installId.isEmpty) {
      throw ArgumentError('installId is required');
    }
    final info = await AppService().getAppInstallInfo(installId);
    // 详情接口不带图标与目录名，按 appKey 取目录条目补齐。
    var icon = info.icon ?? '';
    var catalogName = info.appName ?? '';
    final appKey = info.appKey ?? '';
    if (appKey.isNotEmpty && (icon.isEmpty || catalogName.isEmpty)) {
      try {
        final catalog = await AppService().getAppByKey(appKey);
        if (icon.isEmpty) icon = catalog.icon ?? '';
        if (catalogName.isEmpty) catalogName = catalog.name ?? '';
      } catch (e) {
        appLogger.w('getAppInstallInfo: catalog lookup for $appKey failed: $e');
      }
    }
    return {
      'id': info.id,
      'name': info.name,
      'appName': catalogName,
      'appKey': appKey,
      'version': info.version ?? '',
      'status': info.status ?? '',
      'message': info.message ?? '',
      'httpPort': info.httpPort,
      'httpsPort': info.httpsPort,
      'container': info.container ?? '',
      'appType': info.appType ?? '',
      'createdAt': info.createdAt ?? '',
      'icon': icon,
    };
  }

  /// 已安装应用参数。参数：`{installId: int}`。
  static Future<dynamic> getAppInstallParams(dynamic arguments) async {
    final installId = arguments['installId']?.toString() ?? '';
    if (installId.isEmpty) {
      throw ArgumentError('installId is required');
    }
    final config = await AppService().getAppInstallParams(installId);
    return {
      'containerName': config.containerName,
      'cpuQuota': config.cpuQuota,
      'memoryLimit': config.memoryLimit,
      'memoryUnit': config.memoryUnit,
      'webUI': config.webUI,
      'type': config.type,
      'specifyIP': config.specifyIP ?? '',
      'restartPolicy': config.restartPolicy ?? '',
      'allowPort': config.allowPort,
      'hostMode': config.hostMode ?? false,
      'params': config.params
          .map((param) => {
                'key': param.key,
                'labelZh': param.labelZh,
                'labelEn': param.labelEn,
                'type': param.type,
                'value': param.value?.toString() ?? '',
                'showValue': param.showValue ?? '',
                'edit': param.edit,
                'required': param.required ?? false,
                'multiple': param.multiple ?? false,
              })
          .toList(),
    };
  }

  /// 应用目录条目。参数：`{key: String}`。
  static Future<dynamic> getAppDetailByKey(dynamic arguments) async {
    final key = arguments['key'] as String? ?? '';
    if (key.isEmpty) {
      throw ArgumentError('key is required');
    }
    final app = await AppService().getAppByKey(key);
    return {
      'id': app.id,
      'name': app.name ?? '',
      'key': app.key ?? key,
      'type': app.type ?? '',
      'icon': app.icon ?? '',
      'shortDescZh': app.shortDescZh ?? '',
      'shortDescEn': app.shortDescEn ?? '',
      'description': app.description ?? '',
      'readMe': app.readMe ?? '',
      'website': app.website ?? '',
      'github': app.github ?? '',
      'versions': app.versions ?? const <String>[],
      'installed': app.installed ?? false,
      'gpuSupport': app.gpuSupport ?? false,
      'memoryRequired': app.memoryRequired ?? 0,
      'architectures': app.architectures ?? '',
    };
  }

  static Future<dynamic> getWebsites(dynamic arguments) async {
    final service = WebsitesService();
    final websites = await service.fetchWebsites();
    return websites
        .map((w) => {
              'id': w.id,
              'primaryDomain': w.primaryDomain,
              'status': w.status,
              'remark': w.remark,
              'createdAt': w.createdAt,
            })
        .toList();
  }

  /// 建站表单预载数据：分组、PHP 运行环境、可作父站点的网站。
  /// 应用商店列表。参数：`{search?}`。
  static Future<dynamic> getAppStore(dynamic arguments) async {
    final service = AppService();
    final search = (arguments['search'] as String?)?.trim() ?? '';
    final response = await service.searchApps(AppSearchRequest(
      page: 1,
      pageSize: 100,
      name: search.isEmpty ? null : search,
      showCurrentArch: true,
    ));
    return response.items
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'key': item.key,
              'type': item.type,
              'versions': item.versions,
              'installed': item.installed,
              'description': item.description,
              'icon': item.icon ?? '',
            })
        .toList();
  }

  /// 应用版本列表。参数：`{key}`。
  static Future<dynamic> getAppVersions(dynamic arguments) async {
    final service = AppService();
    final key = arguments['key'] as String;
    final app = await service.getAppByKey(key);
    return {
      'versions': app.versions ?? const <String>[],
      'type': app.type,
    };
  }

  /// 安装表单：按应用与版本返回 appDetailId 与动态字段。
  /// 参数：`{appId, version, type?}`。
  ///
  /// 字段取值统一成 `{label, value}`：上游 `select` 的 values 是字符串，
  /// `apps`（依赖应用，如 WordPress 的数据库服务）的 values 是对象。
  static Future<dynamic> getAppInstallForm(dynamic arguments) async {
    final service = AppService();
    final appId = arguments['appId'].toString();
    final version = arguments['version'] as String;
    final type = arguments['type'] as String? ?? 'app';
    final detail = await service.getAppDetail(appId, version, type);
    final fields = detail.params?.formFields ?? const <AppFormField>[];
    return {
      'appDetailId': detail.id,
      'fields': fields.map(_formFieldPayload).toList(),
    };
  }

  static Map<String, dynamic> _formFieldPayload(AppFormField field) {
    return {
      'envKey': field.envKey,
      'key': field.key,
      'labelZh': field.labelZh,
      'labelEn': field.labelEn,
      'type': field.type,
      'required': field.required,
      'defaultValue': field.defaultValue?.toString(),
      'values': (field.values ?? const <dynamic>[])
          .map((value) {
            if (value is Map) {
              return {
                'label': value['label']?.toString() ?? '',
                'value': value['value']?.toString() ?? '',
              };
            }
            return {'label': value.toString(), 'value': value.toString()};
          })
          .toList(),
      'child': field.child == null
          ? null
          : {
              'envKey': field.child!.envKey,
              'type': field.child!.type,
            },
    };
  }

  static Future<dynamic> getWebsiteCreateOptions(dynamic arguments) async {
    final repository = WebsiteRepository();
    final groups = await repository.listWebsiteGroups();
    final runtimes = await repository.listPhpRuntimes();
    final parents = await repository.listParentWebsites();
    appLogger.d(
      'website create options: groups=${groups.length} '
      'runtimes=${runtimes.length} parents=${parents.length}',
    );
    return {
      'groups': groups
          .where((group) => group.id != null)
          .map((group) => {'id': group.id, 'name': group.name ?? ''})
          .toList(),
      'runtimes': runtimes
          .where((runtime) => runtime.id != null)
          .map((runtime) => {'id': runtime.id, 'name': runtime.name ?? ''})
          .toList(),
      'parentWebsites': parents
          .where((website) => website.id != null)
          .map((website) => {
                'id': website.id,
                'primaryDomain': website.primaryDomain ?? '',
              })
          .toList(),
    };
  }

  /// 网站详情。参数：`{id: int}`。
  static Future<dynamic> getWebsiteDetail(dynamic arguments) async {
    final rawId = arguments['id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());
    final repository = WebsiteRepository();
    final website = await repository.getWebsiteDetail(id);
    return {
      'id': website.id,
      'alias': website.alias,
      'primaryDomain': website.primaryDomain,
      'type': website.type,
      'status': website.status,
      'remark': website.remark,
      'group': website.group,
      'domains': website.domains
          .map((domain) => {
                'id': domain.id,
                'domain': domain.domain,
                'port': domain.port,
                'ssl': domain.ssl,
              })
          .toList(),
    };
  }

  static Future<dynamic> getMonitoring(dynamic arguments) async {
    final service = MonitoringService();
    final metrics = await service.getCurrentMetrics();
    return {
      'cpu': metrics.cpuPercent,
      'memory': metrics.memoryPercent,
      'disk': metrics.diskPercent,
      'load1': metrics.load1,
      'load5': metrics.load5,
      'load15': metrics.load15,
    };
  }

  static Future<dynamic> getContainers(dynamic arguments) async {
    final containers = await ContainerService().listContainers();
    return containers
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'image': c.image,
              'status': c.status,
              'state': c.state,
              'createTime': c.createTime,
              'cpuUsage': c.cpuUsage,
              'memoryUsage': c.memoryUsage,
            })
        .toList();
  }

  /// 容器日志（SSE 帧已由服务层剥离）。参数：`{name: String, tail?: String}`
  static Future<dynamic> getContainerLogs(dynamic arguments) async {
    final name = arguments['name'] as String;
    final tail = arguments['tail'] as String?;
    return ContainerService().getContainerLogs(name, tail: tail);
  }

  /// 容器镜像列表（`/containers/image/all`）。字段与上游真实返回一致。
  static Future<dynamic> getContainerImages(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/all'),
    );
    final items = ApiResponseParser.asList(response.data);
    return items
        .whereType<Map>()
        .map((item) => {
              'id': item['id']?.toString() ?? '',
              'tags': (item['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
              'size': item['size'] ?? 0,
              'createdAt': item['createdAt']?.toString() ?? '',
              'isUsed': item['isUsed'] ?? false,
              'description': item['description']?.toString() ?? '',
            })
        .toList();
  }

  /// 容器网络列表（`/containers/network/search`）。参数：`{page?, pageSize?}`。
  static Future<dynamic> getContainerNetworks(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/network/search'),
      data: <String, dynamic>{
        'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        'pageSize': int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50,
      },
    );
    final items = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return items
        .whereType<Map>()
        .map((item) => {
              'id': item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'driver': item['driver']?.toString() ?? '',
              'subnet': item['subnet']?.toString() ?? '',
              'gateway': item['gateway']?.toString() ?? '',
              'createdAt': item['createdAt']?.toString() ?? '',
              'attachable': item['attachable'] ?? false,
            })
        .toList();
  }

  /// 容器存储卷列表（`/containers/volume/search`）。参数：`{page?, pageSize?}`。
  static Future<dynamic> getContainerVolumes(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/volume/search'),
      data: <String, dynamic>{
        'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        'pageSize': int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50,
      },
    );
    final items = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return items
        .whereType<Map>()
        .map((item) => {
              'name': item['name']?.toString() ?? '',
              'driver': item['driver']?.toString() ?? '',
              'mountpoint': item['mountpoint']?.toString() ?? '',
              'createdAt': item['createdAt']?.toString() ?? '',
            })
        .toList();
  }

  /// 监听端口进程列表。参数：无。POST /process/listening。
  static Future<dynamic> getListeningProcesses(dynamic arguments) async {
    try {
      final processes = (await (await ApiClientManager.instance.getProcessApi())
                  .getListeningProcesses())
              .data ??
          const <ListeningProcess>[];
      return processes
          .map((process) => {
                'pid': process.pid,
                'protocol': process.protocol,
                'name': process.name,
                'ports': process.ports,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get listening processes for native: $e');
      return [];
    }
  }

  /// 容器镜像仓库列表。参数：无。GET /containers/repo。
  static Future<dynamic> getContainerRepos(dynamic arguments) async {
    try {
      final response = await (await ApiClientManager.instance.getContainerApi())
          .getRepos();
      return (response.data ?? const <ContainerRepo>[])
          .map((repo) => repo.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container repos for native: $e');
      return [];
    }
  }

  /// 容器编排模版列表。参数：无。GET /containers/template。
  static Future<dynamic> getContainerTemplates(dynamic arguments) async {
    try {
      final response =
          await (await ApiClientManager.instance.getContainerApi()).getTemplates();
      return (response.data ?? const <ContainerTemplate>[])
          .map((template) => template.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container templates for native: $e');
      return [];
    }
  }

  /// 容器内文件列表。参数：`{containerId: String, path: String}`。
  static Future<dynamic> getContainerFiles(dynamic arguments) async {
    try {
      final containerId = (arguments?['containerId'] as String? ?? '').trim();
      final path = (arguments?['path'] as String? ?? '/').trim();
      if (containerId.isEmpty) {
        return [];
      }
      final response =
          await (await ApiClientManager.instance.getFileApi()).searchContainerFiles(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return (response.data ?? const <ContainerFileInfo>[])
          .map((file) => file.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container files for native: $e');
      return [];
    }
  }

  /// 容器内文件内容。参数：`{containerId: String, path: String}`。
  static Future<dynamic> getContainerFileContent(dynamic arguments) async {
    try {
      final containerId = (arguments?['containerId'] as String? ?? '').trim();
      final path = (arguments?['path'] as String? ?? '').trim();
      if (containerId.isEmpty || path.isEmpty) {
        return <String, dynamic>{};
      }
      final response =
          await (await ApiClientManager.instance.getFileApi()).getContainerFileContent(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data?.toJson() ?? <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get container file content for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 系统日志文件列表（B15 日志模块的只读入口）。
  static Future<dynamic> getSystemLogFiles(dynamic arguments) async {
    try {
      return await LogsService().loadSystemLogFiles();
    } catch (e) {
      appLogger.e('Failed to get system log files for native: $e');
      return <String>[];
    }
  }

  /// 容器 inspect（格式化 JSON）。参数：`{name}`。
  static Future<dynamic> getContainerInspect(dynamic arguments) async {
    final name = arguments['name'] as String;
    final service = ContainerService();
    return service.inspectContainerFormatted(name);
  }

  static Future<String> getUIRenderMode() async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode(refresh: true);
    return mode.name;
  }

  static Future<dynamic> getSettings(dynamic arguments) async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode(refresh: true);
    final locale = await prefs.loadLocale();
    return {
      'renderMode': mode.name,
      'language': locale?.languageCode ?? 'system',
    };
  }

  static Future<dynamic> getTranslations() async {
    final prefs = AppPreferencesService();
    var locale = await prefs.loadLocale(refresh: true);
    if (locale == null) {
      final sysLocale = Platform.localeName;
      if (sysLocale.startsWith('zh')) {
        locale = const Locale('zh');
      } else {
        locale = const Locale('en');
      }
    }
    String arbPath = 'lib/l10n/app_en.arb';
    if (locale.languageCode == 'zh') {
      arbPath = 'lib/l10n/app_zh.arb';
    }
    appLogger.d('translations served for locale ${locale.languageCode}');
    try {
      final jsonString = await rootBundle.loadString(arbPath);
      final Map<String, dynamic> translations = jsonDecode(jsonString);
      translations.removeWhere((key, value) => key.startsWith('@'));
      return translations;
    } catch (e) {
      appLogger.e('Failed to load translations: $e');
      return {};
    }
  }

  // ── 新增 handlers ────────────────────────────────────────────────────────

  /// 仪表盘：返回 CPU/内存/磁盘/运行时长/系统信息。
  static Future<dynamic> getDashboard(dynamic arguments) async {
    try {
      final service = DashboardService();
      final data = await service.loadDashboardData();
      final m = data.metrics;
      final s = data.systemInfo;
      return {
        'cpu': data.cpuPercent ?? m?.cpuPercent ?? 0.0,
        'memory': data.memoryPercent ?? m?.memoryPercent ?? 0.0,
        'disk': data.diskPercent ?? m?.diskPercent ?? 0.0,
        'memoryUsage': data.memoryUsage,
        'diskUsage': data.diskUsage,
        'uptime': data.uptime,
        'hostname': s?.hostname ?? m?.hostname ?? '',
        'os': s?.os ?? m?.os ?? '',
        'kernelVersion': s?.kernelVersion ?? m?.kernelVersion ?? '',
        'cpuCores': s?.cpuCores ?? m?.cpuCores ?? 0,
        'load1': m?.cpuPercent ?? 0.0,
        'panelVersion': s?.panelVersion ?? '',
      };
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('Native dashboard polling skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get dashboard for native: $e');
      }
      return <String, dynamic>{};
    }
  }

  /// 数据库：遍历所有 scope，合并返回数据库列表。
  static Future<dynamic> getDatabases(dynamic arguments) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) return <Map<String, dynamic>>[];
    final service = DatabasesService(
      repository: DatabaseRepository(config: config),
    );
    final result = <Map<String, dynamic>>[];
    for (final scope in DatabaseScope.values) {
      try {
        final page = await service.loadPage(scope: scope, pageSize: 100);
        for (final item in page.items) {
          result.add({
            'id': item.id,
            'name': item.name,
            'lookupName': item.lookupName,
            'source': item.source,
            'type': scope.value,
            'engine': item.engine,
            'serverId': config.id,
            'version': item.version ?? '',
            'status': item.status ?? '',
            'username': item.username ?? '',
            'description': item.description ?? '',
          });
        }
      } catch (e) {
        if (e.toString().contains('No API config available')) {
          appLogger.i('getDatabases scope=$scope skipped: No active server configured.');
        } else {
          appLogger.w('getDatabases scope=$scope failed: $e');
        }
      }
    }
    return result;
  }


  /// SSH 服务信息（B15）。
  /// 上游该端点需要读取 sshd 状态，部分主机需要 20 秒以上；
  /// 客户端默认 8 秒超时会被中断，这里按单次请求放宽到 6 分钟。
  static Future<dynamic> getSshInfo(dynamic arguments) async {
    try {
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/hosts/ssh/search'),
        data: const <String, dynamic>{},
        options: Options(receiveTimeout: const Duration(minutes: 6)),
      );
      return ApiResponseParser.asMap(response.data);
    } catch (e) {
      appLogger.e('Failed to get ssh info for native: $e');
      return <String, dynamic>{'loadFailed': true};
    }
  }

  /// SSH 原始配置文本（B15）。
  static Future<dynamic> getSshConfig(dynamic arguments) async {
    try {
      return await SSHService().loadRawConfig();
    } catch (e) {
      appLogger.e('Failed to get ssh config for native: $e');
      return '';
    }
  }

  /// 工具箱设备快照（B15）。
  static Future<dynamic> getDeviceSnapshot(dynamic arguments) async {
    try {
      final snapshot = await ToolboxDeviceService().loadSnapshot();
      final base = snapshot.baseInfo;
      return {
        'dns': base.dns ?? '',
        'hostname': base.hostname ?? '',
        'localTime': base.localTime ?? '',
        'ntp': base.ntp ?? '',
        'productName': base.productName ?? '',
        'productVersion': base.productVersion ?? '',
        'systemName': base.systemName ?? '',
        'systemVersion': base.systemVersion ?? '',
        'timeZone': base.timeZone ?? '',
        'swapMemoryTotal': base.swapMemoryTotal ?? 0,
        'users': snapshot.users,
      };
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getDeviceSnapshot skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get device snapshot for native: $e');
      }
      return <String, dynamic>{};
    }
  }


  // ── 日志（B16，只读）────────────────────────────────────────────────────

  /// 操作日志分页列表。参数：`{page?: int, pageSize?: int}`
  static Future<dynamic> getOperationLogs(dynamic arguments) async {
    try {
      final service = LogsService();
      final page = await service.searchOperationLogs(OperationLogSearchRequest(
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
      ));
      return page.items
          .map((e) => {
                'id': e.id ?? 0,
                'source': e.source ?? '',
                'ip': e.ip ?? '',
                'path': e.path ?? '',
                'method': e.method ?? '',
                'status': e.status ?? '',
                'message': e.message ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get operation logs for native: $e');
      return [];
    }
  }

  /// 登录日志分页列表。参数：`{page?: int, pageSize?: int}`
  static Future<dynamic> getLoginLogs(dynamic arguments) async {
    try {
      final service = LogsService();
      final page = await service.searchLoginLogs(LoginLogSearchRequest(
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
      ));
      return page.items
          .map((e) => {
                'id': e.id ?? 0,
                'ip': e.ip ?? '',
                'address': e.address ?? '',
                'status': e.status ?? '',
                'message': e.message ?? '',
                'createdAt': e.createdAt ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get login logs for native: $e');
      return [];
    }
  }

  /// 系统日志文件内容。参数：`{fileName: String 必填, useCoreLogs?: bool}`
  static Future<dynamic> getSystemLogContent(dynamic arguments) async {
    try {
      final fileName = (arguments?['fileName'] as String? ?? '').trim();
      if (fileName.isEmpty) {
        return '';
      }
      final response = await LogsService().loadSystemLogContent(
        fileName: fileName,
        useCoreLogs: arguments?['useCoreLogs'] == true,
      );
      return {'lines': response.lines, 'totalLines': response.totalLines};
    } catch (e) {
      appLogger.e('Failed to get system log content for native: $e');
      return {'lines': <String>[], 'totalLines': 0};
    }
  }

  /// 任务日志分页列表。参数：`{page?: int, pageSize?: int, type?: String, status?: String}`
  static Future<dynamic> getTaskLogs(dynamic arguments) async {
    try {
      final page = await LogsService().searchTaskLogs(TaskLogSearch(
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
        type: (arguments?['type'] as String?)?.trim().isEmpty == true
            ? null
            : arguments?['type'] as String?,
        status: (arguments?['status'] as String?)?.trim().isEmpty == true
            ? null
            : arguments?['status'] as String?,
      ));
      return page.items
          .map((e) => {
                'id': e.id ?? '',
                'name': e.name ?? '',
                'type': e.type ?? '',
                'status': e.status ?? '',
                'errorMsg': e.errorMsg ?? '',
                'currentStep': e.currentStep ?? '',
                'logFile': e.logFile ?? '',
                'resourceId': e.resourceId ?? 0,
                'operationLogId': e.operationLogId ?? 0,
                'createdAt': e.createdAt ?? '',
                'endAt': e.endAt ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get task logs for native: $e');
      return [];
    }
  }

  /// 任务日志内容。参数：
  /// `{taskId: String 必填, taskType?, taskOperate?, resourceId?: int, page?, pageSize?}`
  static Future<dynamic> getTaskLogContent(dynamic arguments) async {
    try {
      final taskId = (arguments?['taskId'] as String? ?? '').trim();
      if (taskId.isEmpty) {
        return {'lines': <String>[], 'taskStatus': ''};
      }
      final response = await LogsService().loadTaskLogContent(
        taskId: taskId,
        taskType: arguments?['taskType'] as String?,
        taskOperate: arguments?['taskOperate'] as String?,
        resourceId: int.tryParse('${arguments?['resourceId'] ?? ''}'),
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 200}') ?? 200,
      );
      return {
        'lines': response.lines,
        'taskStatus': response.taskStatus ?? '',
        'totalLines': response.totalLines,
        'end': response.end,
      };
    } catch (e) {
      appLogger.e('Failed to get task log content for native: $e');
      return {'lines': <String>[], 'taskStatus': ''};
    }
  }

  // ── OpenResty（B16）─────────────────────────────────────────────────────

  /// OpenResty 快照（状态/模块/HTTPS/配置源文本）。
  static Future<dynamic> getOpenrestySnapshot(dynamic arguments) async {
    try {
      final snapshot = await OpenRestyService().loadSnapshot();
      return {
        'status': snapshot.status,
        'modules': snapshot.modules,
        'https': snapshot.https,
        'configContent': snapshot.configContent,
      };
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getOpenrestySnapshot skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get openresty snapshot for native: $e');
      }
      return <String, dynamic>{};
    }
  }


  /// Compose 项目内容。参数：`{path: String}`。POST /containers/compose。
  static Future<dynamic> getComposeContent(dynamic arguments) async {
    try {
      final path = (arguments?['path'] as String? ?? '').trim();
      if (path.isEmpty) {
        return '';
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/compose'),
        data: <String, dynamic>{'path': path},
      );
      final data = response.data?['data'];
      return data is String ? data : '';
    } catch (e) {
      appLogger.e('Failed to get compose content for native: $e');
      return '';
    }
  }

  /// Compose 项目容器列表。参数：`{name: String}`。POST /containers/search。
  static Future<dynamic> getComposeContainers(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return [];
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/search'),
        data: <String, dynamic>{
          'page': 1,
          'pageSize': 100,
          'compose': name,
        },
      );
      final items = ApiResponseParser.asList(
        response.data,
        nestedItemsKey: 'items',
      );
      return items
          .whereType<Map>()
          .map((item) => <String, Object?>{
                'id': item['id']?.toString() ?? '',
                'name': item['name']?.toString() ?? '',
                'image': item['image']?.toString() ?? '',
                'state': item['state']?.toString() ?? '',
                'status': item['status']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get compose containers for native: $e');
      return [];
    }
  }

  /// Compose 项目日志：汇总项目内各容器日志。参数：`{name: String, tail?: String}`。
  static Future<dynamic> getComposeLogs(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return '';
      }
      final tail = (arguments?['tail'] as String? ?? '').trim();
      final containers = await getComposeContainers({'name': name});
      final buffer = StringBuffer();
      for (final raw in (containers as List).whereType<Map>()) {
        final containerName = '${raw['name'] ?? ''}';
        if (containerName.isEmpty) continue;
        final logs = await ContainerService().getContainerLogs(
          containerName,
          tail: tail.isEmpty ? null : tail,
        );
        buffer.writeln('===== $containerName =====');
        buffer.writeln(logs);
      }
      return buffer.toString();
    } catch (e) {
      appLogger.e('Failed to get compose logs for native: $e');
      return '';
    }
  }

  /// Compose 项目列表（B18）。
  static Future<dynamic> getComposes(dynamic arguments) async {
    try {
      final service = OrchestrationService();
      final composes = await service.loadComposes(pageSize: 100);
      return composes
          .map((c) => {
                'id': c.id.isEmpty ? c.name : c.id,
                'name': c.name,
                'path': c.path ?? '',
                'version': c.version ?? '',
                'status': c.status ?? '',
                'createTime': c.createTime ?? '',
                'containerCount': c.containerCount ?? 0,
                'runningCount': c.runningCount ?? 0,
              })
          .toList();
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getComposes skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get composes for native: $e');
      }
      return [];
    }
  }

  /// 面板 SSL 信息（B18）。
  static Future<dynamic> getPanelSslInfo(dynamic arguments) async {
    try {
      final info = await PanelSslService().getSslInfo();
      return {'enabled': info.isNotEmpty, ...info};
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getPanelSslInfo skipped: No active server configured.');
        return <String, dynamic>{};
      }
      appLogger.e('Failed to get panel ssl info for native: $e');
      return null;
    }
  }

  /// 网站证书列表（B18，核心字段）。
  static Future<dynamic> getWebsiteCertificates(dynamic arguments) async {
    try {
      final certs = await WebsiteCertificateService().searchCertificates(
        pageSize: 50,
        // 对齐上游 frontend 默认排序（updated_at）；expire_date 列在
        // 服务端排序实现下返回空列表（2026-09-09 生产实证）。
        orderBy: 'updated_at',
        order: 'descending',
      );
      return certs
          .map((c) => {
                'id': c.id ?? 0,
                'primaryDomain': c.primaryDomain ?? '',
                'domains': c.domains ?? const <String>[],
                'provider': c.provider ?? '',
                'type': c.type ?? '',
                'status': c.status ?? '',
                'autoRenew': c.autoRenew ?? false,
                'startDate': c.startDate ?? '',
                'expireDate': c.expireDate ?? '',
                'createdAt': c.createdAt ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get website certificates for native: $e');
      return [];
    }
  }


  /// 脚本库列表（B20，只读；运行/同步走脚本执行通道属范围外）。
  static Future<dynamic> getScripts(dynamic arguments) async {
    try {
      final service = ScriptLibraryService();
      final page = await service.searchScripts(ScriptLibraryQuery(
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 100}') ?? 100,
      ));
      // groupBelong 是 List<String>（契约偏差：Swagger 声明 string）——
      // 嵌套可空列表在 codec 上曾致 C# 端收 null，序列化为逗号串规避。
      final result = page.items
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'label': s.label,
                'isInteractive': s.isInteractive,
                'isSystem': s.isSystem,
                'description': s.description,
                'groupBelong': s.groupBelong.join(','),
                // createdAt 是 DateTime?——StandardMessageCodec 不支持 DateTime，
                // 直接编码会抛异常致整条回复失败（C# 端收 null）。
                'createdAt': s.createdAt?.toIso8601String() ?? '',
              })
          .toList();
      return result;
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getScripts skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get scripts for native: $e');
      }
      return [];
    }
  }

  /// 防火墙：返回端口规则列表。
  static Future<dynamic> getFirewallRules(dynamic arguments) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) return [];
    final page = await FirewallService().searchRules(
      page: 1,
      pageSize: 200,
      type: 'port',
      expectedServerId: config.id,
    );
    return firewallRulePayloads(page.items, serverId: config.id);
  }

  /// 防火墙 IP 规则。POST /hosts/firewall/search type=ip。
  static Future<dynamic> getFirewallIpRules(dynamic arguments) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) return [];
    final page = await FirewallService().searchRules(
      page: 1,
      pageSize: 200,
      type: 'ip',
      expectedServerId: config.id,
    );
    return firewallRulePayloads(page.items, serverId: config.id);
  }

  /// 防火墙基础状态。GET /hosts/firewall/base。
  static Future<dynamic> getFirewallBaseInfo(dynamic arguments) async {
    final info = await FirewallService().loadBaseInfo();
    return firewallBasePayload(info);
  }

  /// V2 转发分区：基础信息与结构化转发规则。
  static Future<dynamic> getFirewallV2Forward(dynamic arguments) async {
    final service = FirewallV2Service();
    final base = await service.loadForwardBase();
    final rules = await service.searchForwardRules(pageSize: 100);
    return firewallForwardPayload(base, rules);
  }

  /// V2 Docker 分区：基础信息、策略与发布端口。
  static Future<dynamic> getFirewallV2Docker(dynamic arguments) async {
    final service = FirewallV2Service();
    final ports = await service.loadDockerPorts();
    final endpoints = await service.loadDockerEndpoints();
    return firewallDockerPayload(ports, endpoints);
  }

  /// V2 设置分区：配置、端口白名单与后端分组。
  static Future<dynamic> getFirewallV2Settings(dynamic arguments) async {
    final settings = await FirewallV2Service().loadSettings();
    return firewallSettingsPayload(settings);
  }

  /// 定时任务：返回任务列表（含下次执行时间预览）。
  static Future<dynamic> getCronJobs(dynamic arguments) async {
    try {
      final service = CronjobRepository();
      final page = await service.searchCronjobsWithPreview(
        const CronjobListQuery(page: 1, pageSize: 100),
      );
      return page.items
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'type': c.type,
                'status': c.status,
                'spec': c.spec,
                'lastRecordStatus': c.lastRecordStatus,
                'lastRecordTime': c.lastRecordTime,
                'nextHandle': c.nextHandlePreview ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get cronjobs for native: $e');
      return [];
    }
  }

  /// 计划任务详情。参数：`{id: int}`。POST /cronjobs/load/info。
  static Future<dynamic> getCronJobInfo(dynamic arguments) async {
    final id = int.tryParse('${arguments['id'] ?? ''}');
    if (id == null) {
      throw ArgumentError('id is required');
    }
    final api = await ApiClientManager.instance.getCronjobApi();
    final response = await api.loadCronjobInfo(id);
    final info = response.data;
    if (info == null) {
      return <String, dynamic>{};
    }
    return {
      'id': info.id,
      'name': info.name,
      'type': info.type,
      'groupID': info.groupID,
      'spec': info.spec,
      'specCustom': info.specCustom,
      'script': info.script,
      'command': info.command,
      'scriptMode': info.scriptMode,
      'status': info.status,
    };
  }

  /// 计划任务执行记录。参数：`{id: int, page?: int, pageSize?: int}`。
  static Future<dynamic> getCronJobRecords(dynamic arguments) async {
    final id = int.tryParse('${arguments['id'] ?? ''}');
    if (id == null) {
      throw ArgumentError('id is required');
    }
    final page = int.tryParse('${arguments['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments['pageSize'] ?? 50}') ?? 50;
    final result = await CronjobRepository().searchRecords(
      CronjobRecordQuery(cronjobId: id, page: page, pageSize: pageSize),
    );
    return {
      'total': result.total,
      'items': result.items
          .map((record) => {
                'id': record.id,
                'taskId': record.taskId,
                'startTime': record.startTime,
                'status': record.status,
                'message': record.message,
                'file': record.file,
              })
          .toList(),
    };
  }

  /// 备份：返回备份记录列表。
  static Future<dynamic> getBackups(dynamic arguments) async {
    try {
      final service = BackupRecordService();
      final records = await service.loadRecords();
      return records
          .map((item) => {
                'id': item.record.id ?? 0,
                'name': item.record.name,
                'type': item.record.type,
                'size': item.size ?? item.record.size,
                'status': item.record.status,
                'createdAt': item.record.createdAt ?? '',
                'backupTime': item.record.backupTime ?? '',
                // 恢复操作所需字段（B13）：
                'detailName': item.record.detailName ?? '',
                'fileName': item.record.fileName ?? '',
                'fileDir': item.record.fileDir ?? '',
                'downloadAccountID': item.record.downloadAccountID ?? 0,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get backups for native: $e');
      return [];
    }
  }

  /// AI 模型：返回 Ollama 模型列表。
  static Future<dynamic> getAIModels(dynamic arguments) async {
    try {
      final repository = AIRepository();
      final page = await repository.searchOllamaModels(page: 1, pageSize: 100);
      return page.items
          .map((m) => {
                'id': m.id,
                'name': m.name ?? '',
                'size': m.size ?? '',
                'modified': m.modified ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get AI models for native: $e');
      return [];
    }
  }

  // ── 网站配置中心（B1，只读）─────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b1_website_channel_contract.md。
  // 读语义：返回原始解析数据（列表/映射透传，不做字段裁剪），失败返回空。

  /// 网站 HTTPS 配置。参数：`{id: int}`。GET /websites/{id}/https。
  static Future<dynamic> getWebsiteHttpsConfig(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      // 服务端返回 {enable, SSL, httpConfig, SSLProtocol, algorithm, hsts,
      // hstsIncludeSubDomains, http3}；WebsiteHttpsConfig.toJson 保留同键透传。
      final config = await (await _websiteApi()).getWebsiteHttps(id);
      return config.toJson();
    } catch (e) {
      appLogger.e('Failed to get website https config for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站反向代理列表。参数：`{id: int}`。POST /websites/proxies。
  static Future<dynamic> getWebsiteProxies(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return [];
      }
      // WebsiteV2Api.getWebsiteProxy 用 asMap 解析，而服务端 data 是数组
      // （上游 GetProxies 返回 []WebsiteProxyConfig），asMap 会得到空 Map——
      // 按真实返回改用原始列表解析，website_v2.dart 不改动。
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/websites/proxies'),
        data: {'id': id},
      );
      return ApiResponseParser.asList(response.data);
    } catch (e) {
      appLogger.e('Failed to get website proxies for native: $e');
      return [];
    }
  }

  /// 网站重定向列表。参数：`{websiteID: int}`。POST /websites/redirect。
  static Future<dynamic> getWebsiteRedirects(dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments?['websiteID'] ?? ''}');
      if (websiteID == null) {
        return [];
      }
      return await (await _websiteApi())
          .getWebsiteRedirectConfig({'websiteID': websiteID});
    } catch (e) {
      appLogger.e('Failed to get website redirects for native: $e');
      return [];
    }
  }

  /// 网站伪静态配置。参数：`{websiteID: int, name: String}`。POST /websites/rewrite。
  static Future<dynamic> getWebsiteRewrite(dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments?['websiteID'] ?? ''}');
      final name = arguments?['name'] as String? ?? '';
      if (websiteID == null || name.isEmpty) {
        return <String, dynamic>{};
      }
      // 返回 {content} 原样透传。
      return await (await _websiteApi())
          .getWebsiteRewrite(websiteId: websiteID, name: name);
    } catch (e) {
      appLogger.e('Failed to get website rewrite for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站 CORS 配置。参数：`{id: int}`。GET /websites/cors/{id}。
  static Future<dynamic> getWebsiteCors(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await _websiteApi()).getWebsiteCorsConfig(id);
    } catch (e) {
      appLogger.e('Failed to get website cors for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站防盗链配置。参数：`{websiteID: int}`。POST /websites/leech。
  static Future<dynamic> getWebsiteLeech(dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments?['websiteID'] ?? ''}');
      if (websiteID == null) {
        return <String, dynamic>{};
      }
      return await (await _websiteApi())
          .getWebsiteLeechConfig({'websiteID': websiteID});
    } catch (e) {
      appLogger.e('Failed to get website leech for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站 BasicAuth 配置。参数：`{websiteID: int}`。POST /websites/auths。
  static Future<dynamic> getWebsiteAuths(dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments?['websiteID'] ?? ''}');
      if (websiteID == null) {
        return <String, dynamic>{};
      }
      // 返回 {enable, items[]} 原样透传。
      return await (await _websiteApi())
          .getWebsiteAuthConfig({'websiteID': websiteID});
    } catch (e) {
      appLogger.e('Failed to get website auths for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站路径 BasicAuth 列表。参数：`{websiteID: int}`。POST /websites/auths/path。
  static Future<dynamic> getWebsitePathAuths(dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments?['websiteID'] ?? ''}');
      if (websiteID == null) {
        return [];
      }
      return await (await _websiteApi())
          .getWebsitePathAuthConfig({'websiteID': websiteID});
    } catch (e) {
      appLogger.e('Failed to get website path auths for native: $e');
      return [];
    }
  }

  /// 网站反向代理缓存配置。参数：`{id: int}`。GET /websites/proxy/config/{id}。
  static Future<dynamic> getWebsiteProxyCache(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await _websiteApi()).getWebsiteProxyCacheConfig(id);
    } catch (e) {
      appLogger.e('Failed to get website proxy cache for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站真实 IP 配置。参数：`{id: int}`。GET /websites/realip/config/{id}。
  static Future<dynamic> getWebsiteRealIP(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await _websiteApi()).getWebsiteRealIpConfig(id);
    } catch (e) {
      appLogger.e('Failed to get website real ip for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站 TCP/UDP 转发配置。参数：`{id: int}`。GET /websites/:id。
  static Future<dynamic> getWebsiteStream(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      final info = await (await _websiteApi()).getWebsiteDetail(id);
      return <String, dynamic>{
        'streamPorts': info.streamPorts ?? '',
        'udp': info.udp ?? false,
        'name': info.primaryDomain ?? info.alias ?? '',
        'algorithm': info.algorithm ?? '',
        'servers': info.servers.map((server) => server.toJson()).toList(),
      };
    } catch (e) {
      appLogger.e('Failed to get website stream for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 网站域名列表。参数：`{id: int}`。GET /websites/domains/{id}。
  static Future<dynamic> getWebsiteDomains(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return [];
      }
      final domains = await (await _websiteApi()).getWebsiteDomains(id);
      return domains.map((d) => d.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get website domains for native: $e');
      return [];
    }
  }

  /// 网站日志（按行分页）。参数：
  /// `{id: int, logType: 'access.log'|'error.log', page?: int, pageSize?: int}`。
  /// POST /websites/log/search。
  static Future<dynamic> getWebsiteLogs(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      // 服务端返回 {enable, content, end, path}（按行分页读文件），
      // WebsiteV2Api.searchWebsiteLogs 按数组解析与真实返回不符——
      // 按真实返回用原始 Map 解析透传，website_v2.dart 不改动。
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/websites/log/search'),
        data: {
          'id': id,
          'logType': arguments?['logType'] as String? ?? 'access.log',
          'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          'pageSize': int.tryParse('${arguments?['pageSize'] ?? 100}') ?? 100,
        },
      );
      return ApiResponseParser.asMap(response.data);
    } catch (e) {
      appLogger.e('Failed to get website logs for native: $e');
      return <String, dynamic>{};
    }
  }

  // ── 文件（B2，只读）────────────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b2_files_channel_contract.md。
  // 读语义：原样透传服务端数据，失败/缺参返回空值并记录日志。

  /// 文件内容。参数：`{path: String 必填}`。
  /// POST /files/content `{path, expand: true}`，返回服务端原始 data 对象
  /// （含 `content` 键），C# 端取 content 字段。
  static Future<dynamic> getFileContentHandler(dynamic arguments) async {
    try {
      final path = arguments?['path'] as String? ?? '';
      if (path.isEmpty) {
        return <String, dynamic>{};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/files/content'),
        data: <String, dynamic>{'path': path, 'expand': true},
      );
      return ApiResponseParser.asMap(response.data);
    } catch (e) {
      appLogger.e('Failed to get file content for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 收藏列表。参数：`{page?: int, pageSize?: int}`（C# 传 `{}` 取默认值）。
  /// POST /files/favorite/search（dto.PageInfo），items 列表原样透传。
  static Future<dynamic> getFavoritesHandler(dynamic arguments) async {
    try {
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/files/favorite/search'),
        data: <String, dynamic>{
          'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          'pageSize': int.tryParse('${arguments?['pageSize'] ?? 100}') ?? 100,
        },
      );
      return ApiResponseParser.asList(response.data, nestedItemsKey: 'items');
    } catch (e) {
      appLogger.e('Failed to get favorites for native: $e');
      return [];
    }
  }

  // ── AI 管理深度（B3，只读）────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b3_ai_channel_contract.md。
  // 读语义：透传解析数据（不做字段裁剪），缺参/失败返回空值并记录日志。

  /// GPU/XPU 负载。参数：`{}`。GET /ai/gpu/load。
  static Future<dynamic> getGpuLoad(dynamic arguments) async {
    try {
      final gpus = await AIRepository().loadGpuInfo();
      return gpus.map((g) => g.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get gpu load for native: $e');
      return [];
    }
  }

  /// GPU 选项（监控图表类型列表）。参数：`{}`。GET /ai/gpu/options。
  static Future<dynamic> getGpuOptions(dynamic arguments) async {
    try {
      return await AIRepository().getGpuOptions();
    } catch (e) {
      appLogger.e('Failed to get gpu options for native: $e');
      return [];
    }
  }

  /// GPU 历史监控。参数：
  /// `{productName: String, startTime: String, endTime: String}`。
  /// POST /ai/gpu/search，返回时间序列列表。
  static Future<dynamic> searchGpuHistory(dynamic arguments) async {
    try {
      final startTime = arguments?['startTime'] as String? ?? '';
      final endTime = arguments?['endTime'] as String? ?? '';
      if (startTime.isEmpty || endTime.isEmpty) {
        return [];
      }
      return await AIRepository().searchGpu(<String, dynamic>{
        'productName': arguments?['productName'] as String? ?? '',
        'startTime': startTime,
        'endTime': endTime,
      });
    } catch (e) {
      appLogger.e('Failed to search gpu history for native: $e');
      return [];
    }
  }

  /// 智能体渠道账号分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/accounts/search。
  static Future<dynamic> getAgentAccounts(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgentAccounts(
        AgentAccountSearch(
          page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
          name: arguments?['name'] as String? ?? '',
        ),
      ))
          .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to get agent accounts for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 渠道账号可选 provider 列表。参数：无。GET /ai/accounts/providers。
  static Future<dynamic> getAgentProviders(dynamic arguments) async {
    try {
      final providers = (await (await AIRepository().getApi())
                  .getAgentProviders())
              .data ??
          const <ProviderInfo>[];
      return providers
          .map((p) => {
                'provider': p.provider,
                'displayName': p.displayName,
                'baseUrl': p.baseUrl,
                'defaultApiType': p.defaultApiType,
                'apiTypes': p.apiTypes,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get agent providers for native: $e');
      return [];
    }
  }

  /// 渠道账号可用模型列表。参数：`{accountId: int}`。POST /ai/accounts/models。
  static Future<dynamic> getAgentAccountModels(dynamic arguments) async {
    try {
      final accountId = int.tryParse('${arguments?['accountId'] ?? ''}');
      if (accountId == null) {
        return [];
      }
      final models = (await (await AIRepository().getApi())
              .getAgentAccountModels(AgentAccountModelReq(accountId: accountId)))
          .data!;
      return models.map((m) => m.toJson()).toList();
    } catch (e) {
      appLogger.e('Failed to get agent account models for native: $e');
      return [];
    }
  }

  /// MCP 服务器分页。参数：`{page: int, pageSize: int, name?: String}`。
  /// POST /ai/mcp/search。
  static Future<dynamic> getMcpServers(dynamic arguments) async {
    try {
      return (await (await AIRepository().getApi()).searchMcpServers(
                McpServerSearch(
                  page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                  pageSize:
                      int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
                  name: arguments?['name'] as String? ?? '',
                ),
              ))
                  .data
                  ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get mcp servers for native: $e');
      return <String, dynamic>{};
    }
  }

  /// MCP 服务器详情。参数：`{id: int}`。POST /ai/mcp/server/detail。
  static Future<dynamic> getMcpServerDetail(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return <String, dynamic>{};
      }
      return await (await AIRepository().getApi())
          .getMcpServerDetail(<String, dynamic>{'id': id})
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get mcp server detail for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体实例分页。参数：`{page: int, pageSize: int}`。POST /ai/agents/search。
  static Future<dynamic> pageAgentsNative(dynamic arguments) async {
    try {
      final page = (await (await AIRepository().getApi()).pageAgents(
              SearchWithPage(
                page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
                pageSize: int.tryParse('${arguments?['pageSize'] ?? 20}') ?? 20,
              ),
            ))
                .data!;
      return <String, dynamic>{
        'items': page.items.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'totalPages': page.totalPages,
      };
    } catch (e) {
      appLogger.e('Failed to page agents for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 智能体总览。参数：`{agentId: int}`。POST /ai/agents/overview。
  static Future<dynamic> getAgentOverviewNative(dynamic arguments) async {
    try {
      final agentId = int.tryParse('${arguments?['agentId'] ?? ''}');
      if (agentId == null) {
        return <String, dynamic>{};
      }
      return (await (await AIRepository().getApi())
                  .getAgentOverview(AgentOverviewReq(agentId: agentId)))
              .data
              ?.toJson() ??
          <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get agent overview for native: $e');
      return <String, dynamic>{};
    }
  }

  /// AI 服务绑定域名。参数：`{appInstallID: int}`。POST /ai/domain/get。
  static Future<dynamic> getAIBindDomain(dynamic arguments) async {
    try {
      final appInstallID = int.tryParse('${arguments?['appInstallID'] ?? ''}');
      if (appInstallID == null) {
        return <String, dynamic>{};
      }
      return (await AIRepository().getBindDomain(appInstallID: appInstallID))
          .toJson();
    } catch (e) {
      appLogger.e('Failed to get AI bind domain for native: $e');
      return <String, dynamic>{};
    }
  }

  // ── 虚拟机 ──────────────────────────────────────────────────────────────

  /// 运行环境探测。GET /vms/environment。
  static Future<dynamic> getVmEnvironment(dynamic arguments) async {
    final environment = await VMService().checkEnvironment();
    return vmEnvironmentPayload(environment);
  }

  /// 实例列表。参数：`{info?: String}`。POST /vms/search。
  static Future<dynamic> getVms(dynamic arguments) async {
    final info = (arguments?['info'] as String? ?? '').trim();
    final result = await VMService().searchVMs(info: info.isEmpty ? null : info);
    return <String, dynamic>{
      'items': result.items.map(vmSummaryPayload).toList(growable: false),
      'total': result.total,
      'limit': result.limit,
    };
  }

  /// 实例详情。参数：`{name: String, checkDisks?: bool}`。POST /vms/info。
  static Future<dynamic> getVmInfo(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final checkDisks = arguments?['checkDisks'] as bool? ?? false;
    final vm = await VMService().getVMInfo(name, checkDisks: checkDisks);
    return vmDetailPayload(vm);
  }

  /// 实例快照。参数：`{name: String}`。
  ///
  /// 恢复快照要求实例处于关机状态，可用性在这里判定。
  static Future<dynamic> getVmSnapshots(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final service = VMService();
    final vm = await service.getVMInfo(name);
    final snapshots = await service.listSnapshots(name);
    final canRecover = vm.status.trim().toLowerCase() == 'shut off';
    return <String, dynamic>{
      'canCreate': vmCapabilitiesPayload(vm)['canCreateSnapshot'],
      'canRecover': canRecover,
      'items': snapshots
          .map((snapshot) =>
              vmSnapshotPayload(snapshot, canRecover: canRecover))
          .toList(growable: false),
    };
  }

  /// 实例健康检查。参数：`{name: String}`。POST /vms/health/check。
  static Future<dynamic> getVmHealth(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final result = await VMService().healthCheck(name);
    return vmHealthPayload(result);
  }

  /// 实时统计采样。参数：`{name: String}`。POST /vms/stats。
  ///
  /// 返回 CPU 与内存百分比、磁盘与网络速率，差值计算在 Dart 侧完成。
  static Future<dynamic> getVmStats(dynamic arguments) async {
    final name = (arguments?['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      throw ArgumentError('name is required');
    }
    final config = await ApiConfigManager.getCurrentServerMetadata();
    final stats = await VMService().getVMStats(name);
    return _vmStatsSampler.sample(
      serverId: config?.id ?? '',
      stats: stats,
    );
  }

  /// ISO 镜像列表。GET /vms/isos。
  static Future<dynamic> getVmIsos(dynamic arguments) async {
    final isos = await VMService().listIso();
    return isos.map(vmIsoPayload).toList(growable: false);
  }

  /// 虚拟机模板列表。POST /vms/templates/list。
  static Future<dynamic> getVmTemplates(dynamic arguments) async {
    final templates = await VMService().listTemplates();
    return templates.map(vmTemplatePayload).toList(growable: false);
  }

  /// 虚拟机网络列表。GET /vms/networks。
  static Future<dynamic> getVmNetworks(dynamic arguments) async {
    final networks = await VMService().listNetworks();
    return networks.map(vmNetworkPayload).toList(growable: false);
  }

  /// 创建网络可选的网桥与宿主机接口。GET /vms/networks/bridges 与 interfaces。
  static Future<dynamic> getVmNetworkOptions(dynamic arguments) async {
    final service = VMService();
    final bridges = await service.listNetworkBridges();
    final interfaces = await service.listNetworkInterfaces();
    return <String, dynamic>{
      'bridges': bridges
          .map((bridge) => <String, Object?>{
                'name': bridge.name,
                'recommended': bridge.recommended,
                'description': bridge.description,
              })
          .toList(growable: false),
      'interfaces': interfaces
          .map((interface) => <String, Object?>{
                'name': interface.name,
                'addresses': interface.addresses,
              })
          .toList(growable: false),
    };
  }

  /// 虚拟机存储池列表。GET /vms/storages。
  static Future<dynamic> getVmStorages(dynamic arguments) async {
    final storages = await VMService().listStorages();
    return storages.map(vmStoragePayload).toList(growable: false);
  }

  // ── 告警中心 ────────────────────────────────────────────────────────────

  /// 告警任务列表。参数：`{page?, pageSize?, type?, status?}`。POST /alert/search。
  static Future<dynamic> getAlertRules(dynamic arguments) async {
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final type = (arguments?['type'] as String? ?? '').trim();
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await AlertService().searchAlerts(
      page: page,
      pageSize: pageSize,
      type: type.isEmpty ? null : type,
      status: status.isEmpty ? null : status,
    );
    return <String, dynamic>{
      'items': result.items.map(alertRulePayload).toList(growable: false),
      'total': result.total,
      'page': result.page,
      'pageSize': result.pageSize,
    };
  }

  /// 告警日志列表。参数：`{page?, pageSize?, status?}`。POST /alert/logs/search。
  static Future<dynamic> getAlertLogs(dynamic arguments) async {
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await AlertService().searchLogs(
      page: page,
      pageSize: pageSize,
      status: status.isEmpty ? null : status,
    );
    return <String, dynamic>{
      'items': result.items.map(alertLogPayload).toList(growable: false),
      'total': result.total,
      'page': result.page,
      'pageSize': result.pageSize,
    };
  }

  /// 通知渠道列表。GET /alert/config/info。
  static Future<dynamic> getAlertChannels(dynamic arguments) async {
    final channels = await AlertService().listConfigs();
    return channels.map(alertChannelPayload).toList(growable: false);
  }

  /// 告警表单选项：磁盘、病毒扫描任务、计划任务、类型与预设。
  static Future<dynamic> getAlertOptions(dynamic arguments) async {
    final service = AlertService();
    final results = await Future.wait(<Future<Object>>[
      service.listDisks(),
      service.listClams(),
      service.listCronJobs(),
    ]);
    return alertOptionsPayload(
      disks: results[0] as List<AlertDisk>,
      clams: results[1] as List<AlertClam>,
      cronJobs: results[2] as List<AlertCronJob>,
    );
  }

  // ── 模型下载器 ──────────────────────────────────────────────────────────

  /// 推荐模型。参数：`{family?, page?, pageSize?}`。POST /xpack/model/downloader/featured/search。
  static Future<dynamic> getModelDownloaderFeatured(dynamic arguments) async {
    final family = (arguments?['family'] as String? ?? '').trim();
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final result = await ModelDownloaderService().searchFeatured(
      page: page,
      pageSize: pageSize,
      family: family.isEmpty ? null : family,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderFeaturedPayload).toList(growable: false),
      'total': result.total,
      'families': result.families,
    };
  }

  /// 市场搜索。参数：`{source: hf|modelScope, query?, sort?, page?, pageSize?}`。
  static Future<dynamic> getModelDownloaderSearch(dynamic arguments) async {
    final source = (arguments?['source'] as String? ?? 'hf').trim();
    final query = (arguments?['query'] as String? ?? '').trim();
    final sort = (arguments?['sort'] as String? ?? 'trending').trim();
    final page = int.tryParse('${arguments?['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final service = ModelDownloaderService();
    final result = source == 'hf'
        ? await service.searchHuggingFace(
            page: page,
            pageSize: pageSize,
            query: query.isEmpty ? null : query,
            sort: sort.isEmpty ? null : sort,
          )
        : await service.searchModelScope(
            page: page,
            pageSize: pageSize,
            query: query.isEmpty ? null : query,
            sort: sort.isEmpty ? null : sort,
          );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderMarketPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 下载任务。参数：`{status?}`。
  static Future<dynamic> getModelDownloaderTasks(dynamic arguments) async {
    final status = (arguments?['status'] as String? ?? '').trim();
    final result = await ModelDownloaderService().searchTasks(
      page: 1,
      pageSize: 100,
      status: status.isEmpty ? null : status,
      includeLocal: true,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderTaskPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 本地模型。参数：`{info?}`。
  static Future<dynamic> getModelDownloaderLocal(dynamic arguments) async {
    final info = (arguments?['info'] as String? ?? '').trim();
    final result = await ModelDownloaderService().searchLocal(
      page: 1,
      pageSize: 100,
      info: info.isEmpty ? null : info,
    );
    return <String, dynamic>{
      'items':
          result.items.map(modelDownloaderLocalPayload).toList(growable: false),
      'total': result.total,
    };
  }

  /// 下载设置。GET /xpack/model/downloader/settings。
  static Future<dynamic> getModelDownloaderSettings(dynamic arguments) async {
    final setting = await ModelDownloaderService().getSettings();
    return modelDownloaderSettingsPayload(setting);
  }

  /// 下载器固定选项：来源、排序、下载内容与任务状态。
  static Future<dynamic> getModelDownloaderOptions(dynamic arguments) async {
    return modelDownloaderOptionsPayload();
  }

  // ── 监控中心 ────────────────────────────────────────────────────────────

  /// 监控历史曲线。参数：`{hours?: int}`，默认 1 小时，上限 168 小时。
  static Future<dynamic> getMonitoringHistory(dynamic arguments) async {
    final requested = int.tryParse('${arguments?['hours'] ?? 1}') ?? 1;
    final hours = requested.clamp(1, 168);
    final package = await MonitoringService().getMonitorData(
      duration: Duration(hours: hours),
    );
    return monitoringHistoryPayload(package);
  }

  /// 监控设置。GET /hosts/monitor/setting。
  static Future<dynamic> getMonitoringSettings(dynamic arguments) async {
    final setting = await MonitoringService().getSetting();
    return monitoringSettingsPayload(setting);
  }

  /// 监控可用网卡与磁盘设备。用于设置的默认网卡与默认磁盘。
  static Future<dynamic> getMonitoringOptions(dynamic arguments) async {
    final service = MonitoringService();
    var networks = const <String>[];
    var ios = const <String>[];
    try {
      networks = await service.getNetworkOptions();
    } catch (e) {
      appLogger.w('getMonitoringOptions networks failed: $e');
    }
    try {
      ios = await service.getIOOptions();
    } catch (e) {
      appLogger.w('getMonitoringOptions io failed: $e');
    }
    return monitoringOptionsPayload(networks: networks, ios: ios);
  }

  // ── 运维模块入口数据 ────────────────────────────────────────────────────

  /// 运行环境列表：按 PHP、Node、Java、Go、Python、.NET 依次汇总。
  static Future<dynamic> getRuntimes(dynamic arguments) async {
    final service = RuntimeService();
    final pages = await Future.wait(
      RuntimeService.orderedTypes.map(
        (type) => service.searchRuntimes(type: type),
      ),
    );
    return pages
        .expand((page) => page.items)
        .map((runtime) => <String, Object?>{
              'id': runtime.id ?? 0,
              'name': runtime.name ?? '',
              'type': runtime.type ?? '',
              'version': runtime.version ?? '',
              'status': runtime.status ?? '',
              'port': runtime.port ?? '',
              'image': runtime.image ?? '',
              'containerStatus': runtime.containerStatus ?? '',
              'remark': runtime.remark ?? '',
            })
        .toList(growable: false);
  }

  /// 工具箱磁盘快照：磁盘与未分区磁盘。
  static Future<dynamic> getToolboxDiskSnapshot(dynamic arguments) async {
    final snapshot = await ToolboxDiskService().loadSnapshot();
    return <String, dynamic>{
      'totalDisks': snapshot.totalDisks,
      'totalCapacity': snapshot.totalCapacity,
      'disks': snapshot.disks
          .map((disk) => <String, Object?>{
                'device': disk.device,
                'model': disk.model,
                'size': disk.size,
                'diskType': disk.diskType,
                'mountPoint': disk.mountPoint,
                'usePercent': disk.usePercent,
                'isSystem': disk.isSystem,
                'isMounted': disk.isMounted,
              })
          .toList(growable: false),
      'unpartitioned': snapshot.unpartitionedDisks
          .map((disk) => <String, Object?>{
                'device': disk.device,
                'model': disk.model,
                'size': disk.size,
                'diskType': disk.diskType,
                'isRemovable': disk.isRemovable,
              })
          .toList(growable: false),
    };
  }

  /// 主机资源列表。POST /hosts/search。
  static Future<dynamic> getHostAssets(dynamic arguments) async {
    final page = await HostAssetService().searchHosts(
      const HostSearchRequest(page: 1, pageSize: 100),
    );
    return page.items
        .map((host) => <String, Object?>{
              'id': host.id,
              'name': host.name,
              'addr': host.addr ?? '',
              'port': host.port ?? 0,
              'user': host.user ?? '',
              'group': host.groupBelong ?? '',
              'status': host.status,
              'osType': host.osType ?? '',
              'osArch': host.osArch ?? '',
            })
        .toList(growable: false);
  }
}

/// 实时统计采样器在通道进程内共享，按服务器与实例名隔离。
final VmStatsSampler _vmStatsSampler = VmStatsSampler();
