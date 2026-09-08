import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/v2/api_response_parser.dart';
import '../../api/v2/website_v2.dart';
import '../../data/models/ai/agent_account_model_pool_models.dart';
import '../../data/models/ai/agent_account_models.dart';
import '../../data/models/ai/agent_core_models.dart';
import '../../data/models/common_models.dart';
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
import '../../features/logs/services/logs_service.dart';
import '../../data/models/logs_models.dart';
import '../../features/openresty/services/openresty_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../../data/models/script_library_models.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/websites/services/website_certificate_service.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/toolbox/services/toolbox_device_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/database_models.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../services/app_preferences_service.dart';
import '../services/logger/logger_service.dart';
import '../theme/ui_render_mode.dart';

/// B1 网站配置中心读通道使用的网站 V2 API（按需构造）。
Future<WebsiteV2Api> _websiteApi() async =>
    WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());

/// 所有 Native Channel 读操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelReadHandlers {
  static String _serializeRenderMode(UIRenderMode mode) {
    return mode == UIRenderMode.native ? 'native' : 'md3';
  }

  // ── 原有 handlers ────────────────────────────────────────────────────────

  static Future<dynamic> getServers(dynamic arguments) async {
    final repository = ServerRepository();
    final servers = await repository.loadServerCards();
    return servers
        .map((s) => {
              'id': s.config.id,
              'name': s.config.name,
              'url': s.config.url,
              'isCurrent': s.isCurrent,
              'cpu': s.metrics.cpuPercent,
              'memory': s.metrics.memoryPercent,
            })
        .toList();
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
    final apps = await service.getInstalledApps();
    return apps
        .map((a) => {
              'name': a.name,
              'status': a.status,
              'version': a.version,
              'appId': a.appId,
            })
        .toList();
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
    try {
      final service = ContainerService();
      final containers = await service.listContainers();
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
    } catch (e) {
      appLogger.e('Failed to get containers for native: $e');
      return [];
    }
  }

  static Future<String> getUIRenderMode() async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode();
    return _serializeRenderMode(mode);
  }

  static Future<dynamic> getSettings(dynamic arguments) async {
    final prefs = AppPreferencesService();
    final mode = await prefs.loadUIRenderMode();
    final locale = await prefs.loadLocale();
    return {
      'renderMode': _serializeRenderMode(mode),
      'language': locale?.languageCode ?? 'system',
      'version': '0.5.0-alpha.1',
    };
  }

  static Future<dynamic> getTranslations() async {
    final prefs = AppPreferencesService();
    var locale = await prefs.loadLocale();
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
    final service = DatabasesService();
    final result = <Map<String, dynamic>>[];
    for (final scope in DatabaseScope.values) {
      try {
        final page = await service.loadPage(scope: scope, pageSize: 100);
        for (final item in page.items) {
          result.add({
            'id': item.id,
            'name': item.name,
            'type': scope.value,
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
  static Future<dynamic> getSshInfo(dynamic arguments) async {
    try {
      final info = await SSHService().loadInfo();
      return {
        'autoStart': info.autoStart,
        'isExist': info.isExist,
        'isActive': info.isActive,
        'message': info.message,
        'port': info.port,
        'listenAddress': info.listenAddress,
        'passwordAuthentication': info.passwordAuthentication,
        'pubkeyAuthentication': info.pubkeyAuthentication,
        'permitRootLogin': info.permitRootLogin,
        'useDNS': info.useDNS,
        'currentUser': info.currentUser,
      };
    } catch (e) {
      appLogger.e('Failed to get ssh info for native: $e');
      return <String, dynamic>{};
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


  /// Compose 项目列表（B18）。
  static Future<dynamic> getComposes(dynamic arguments) async {
    try {
      final service = OrchestrationService();
      final composes = await service.loadComposes(pageSize: 100);
      return composes
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'path': c.path ?? '',
                'version': c.version ?? '',
                'status': c.status ?? '',
                'createTime': c.createTime ?? '',
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
      return await PanelSslService().getSslInfo();
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getPanelSslInfo skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get panel ssl info for native: $e');
      }
      return <String, dynamic>{};
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
                'provider': c.provider ?? '',
                'startDate': c.startDate ?? '',
                'expireDate': c.expireDate ?? '',
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
    try {
      final service = FirewallService();
      final page = await service.searchRules(page: 1, pageSize: 200);
      return page.items
          .map((r) => {
                'id': r.id ?? 0,
                'protocol': r.protocol ?? '',
                'port': r.port ?? '',
                'address': r.address ?? '',
                'strategy': r.strategy ?? '',
                'description': r.description ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get firewall rules for native: $e');
      return [];
    }
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
}
