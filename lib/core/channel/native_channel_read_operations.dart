import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../../api/v2/api_response_parser.dart';
import '../../data/models/logs_models.dart';
import '../../data/models/task_log_models.dart';
import '../../features/firewall/firewall_service.dart';
import '../../features/firewall/firewall_v2_service.dart';
import '../../features/logs/services/logs_service.dart';
import '../../features/openresty/services/openresty_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../../data/models/script_library_models.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/websites/services/website_certificate_service.dart';
import '../services/logger/logger_service.dart';
import 'native_firewall_payloads.dart';

/// 读通道主机运维域：日志、SSH、OpenResty、面板 SSL 与证书、脚本库、
/// 防火墙规则。
class NativeChannelOperationsReadHandlers {
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

  /// 系统日志文件列表（B15 日志模块的只读入口）。
  static Future<dynamic> getSystemLogFiles(dynamic arguments) async {
    try {
      return await LogsService().loadSystemLogFiles();
    } catch (e) {
      appLogger.e('Failed to get system log files for native: $e');
      return <String>[];
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

  // ── SSH（B15）───────────────────────────────────────────────────────────

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

  // ── SSL 与证书 ──────────────────────────────────────────────────────────

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

  // ── 脚本库与防火墙 ──────────────────────────────────────────────────────

  /// 脚本库列表（B20，只读；运行/同步走脚本执行通道属范围外）。
  static Future<dynamic> getScripts(dynamic arguments) async {
    try {
      final service = ScriptLibraryService();
      final page = await service.searchScripts(ScriptLibraryQuery(
        page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        pageSize: int.tryParse('${arguments?['pageSize'] ?? 100}') ?? 100,
      ));
      // groupBelong 是 List<String>（协议偏差：Swagger 声明 string）——
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
}