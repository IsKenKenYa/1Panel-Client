import '../../features/ai/ai_repository.dart';
import '../../features/apps/app_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/containers/container_service.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/firewall/firewall_service.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../core/config/api_config.dart';
import '../../core/config/debug_seed_config.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/app_models.dart';
import '../../data/models/backup_account_models.dart';
import '../../data/models/firewall_models.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/website_repository.dart';
import '../services/logger/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 统一返回结构：成功 `{success: true}`，失败 `{success: false, error: String}`。
Map<String, dynamic> _ok() => {'success': true};
Map<String, dynamic> _err(Object e) => {'success': false, 'error': e.toString()};

/// 所有 Native Channel 写操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelWriteHandlers {
  // ── 服务器 ────────────────────────────────────────────────────────────────

  /// 调试走查种子：原生壳把 `ONEPANEL_SEED_*` 环境变量经通道转发到这里，
  /// 通过正式配置存储写入服务器与 API Key。参数：`{url, apiKey, name?}`。
  static Future<Map<String, dynamic>> seedDebugConfig(dynamic arguments) async {
    if (!kDebugMode) {
      return _err(StateError('seedDebugConfig 仅调试构建可用'));
    }
    try {
      await applySeedConfig(
        url: arguments['url'] as String,
        apiKey: arguments['apiKey'] as String,
        name: arguments['name'] as String?,
      );
      return _ok();
    } catch (e) {
      appLogger.e('seedDebugConfig failed: $e');
      return _err(e);
    }
  }

  /// 新增服务器配置。参数：`{name: String, url: String, apiKey: String}`
  static Future<Map<String, dynamic>> addServer(dynamic arguments) async {
    try {
      final name = arguments['name'] as String;
      final url = arguments['url'] as String;
      final apiKey = arguments['apiKey'] as String;
      final id = 'server_${DateTime.now().microsecondsSinceEpoch}';
      final config = ApiConfig(
        id: id,
        name: name,
        url: url,
        apiKey: apiKey,
      );
      final repository = const ServerRepository();
      await repository.saveConfig(config);
      return _ok();
    } catch (e) {
      appLogger.e('addServer failed: $e');
      return _err(e);
    }
  }

  /// 切换当前服务器。参数：`{id: String}`
  static Future<Map<String, dynamic>> connectServer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final repository = ServerRepository();
      await repository.setCurrent(id);
      return _ok();
    } catch (e) {
      appLogger.e('connectServer failed: $e');
      return _err(e);
    }
  }

  /// 删除服务器配置。参数：`{id: String}`
  static Future<Map<String, dynamic>> deleteServer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final repository = ServerRepository();
      await repository.removeConfig(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteServer failed: $e');
      return _err(e);
    }
  }

  /// 更新服务器配置（名称/地址/API 密钥）。参数：`{id, name, url, apiKey}`
  static Future<Map<String, dynamic>> updateServer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final name = arguments['name'] as String;
      final url = arguments['url'] as String;
      final apiKey = (arguments['apiKey'] as String?) ?? '';
      final configs = await ApiConfigManager.getConfigs();
      final existing = configs.firstWhere((c) => c.id == id);
      final updated = ApiConfig(
        id: existing.id,
        name: name,
        url: url,
        // 编辑时 API Key 留空表示沿用原值。
        apiKey: apiKey.isEmpty ? existing.apiKey : apiKey,
        tokenValidity: existing.tokenValidity,
        allowInsecureTls: existing.allowInsecureTls,
        isDefault: existing.isDefault,
        lastUsed: existing.lastUsed,
      );
      await ApiConfigManager.saveConfig(updated);
      return _ok();
    } catch (e) {
      appLogger.e('updateServer failed: $e');
      return _err(e);
    }
  }

  // ── 网站 ────────────────────────────────────────────────────────────────

  /// 创建网站。参数：
  /// `{alias, type, primaryDomain, groupId, remark?}`
  /// type=runtime 追加 `{runtimeId, siteDir?}`；
  /// type=proxy 追加 `{proxyType, proxy, port?}`；
  /// type=subsite 追加 `{parentWebsiteId}`。
  static Future<Map<String, dynamic>> createWebsite(dynamic arguments) async {
    try {
      final alias = (arguments['alias'] as String).trim();
      final type = arguments['type'] as String;
      final primaryDomain = (arguments['primaryDomain'] as String).trim();
      final groupId = _toInt(arguments['groupId']);
      final remark = (arguments['remark'] as String?)?.trim() ?? '';
      final portRaw = arguments['port'];
      final port =
          portRaw == null ? null : int.tryParse(portRaw.toString());
      final siteDir = (arguments['siteDir'] as String?)?.trim() ?? '';
      final proxy = (arguments['proxy'] as String?)?.trim() ?? '';
      final repository = WebsiteRepository();
      await repository.preCheckWebsite({});
      await repository.createWebsite(WebsiteCreate(
        alias: alias,
        name: primaryDomain,
        remark: remark.isEmpty ? null : remark,
        type: type,
        webSiteGroupId: groupId,
        // 服务端校验 appType 必须是 new 或 installed；建站流程默认复用已安装应用。
        appType: 'installed',
        runtimeId: type == 'runtime' ? _toInt(arguments['runtimeId']) : null,
        siteDir: siteDir.isEmpty ? null : siteDir,
        proxyType:
            type == 'proxy' ? (arguments['proxyType'] as String? ?? 'http') : null,
        proxy: type == 'proxy' ? proxy : null,
        port: port,
        parentWebsiteId:
            type == 'subsite' ? _toInt(arguments['parentWebsiteId']) : null,
        domains: [
          WebsiteDomain(domain: primaryDomain, port: port, ssl: false),
        ],
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
      return _ok();
    } catch (e) {
      appLogger.e('createWebsite failed: $e');
      return _err(e);
    }
  }

  /// 切换网站运行状态。参数：`{id: int, currentStatus: String}`
  static Future<Map<String, dynamic>> toggleWebsiteStatus(
      dynamic arguments) async {
    try {
      final id = _toInt(arguments['id']);
      final currentStatus = arguments['currentStatus'] as String? ?? '';
      final service = WebsitesService();
      if (currentStatus == 'running') {
        await service.stopWebsite(id);
      } else {
        await service.startWebsite(id);
      }
      return _ok();
    } catch (e) {
      appLogger.e('toggleWebsiteStatus failed: $e');
      return _err(e);
    }
  }

  /// 删除网站。参数：`{id: int}`
  static Future<Map<String, dynamic>> deleteWebsite(dynamic arguments) async {
    try {
      final id = _toInt(arguments['id']);
      final service = WebsitesService();
      await service.deleteWebsite(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteWebsite failed: $e');
      return _err(e);
    }
  }

  // ── 容器 ────────────────────────────────────────────────────────────────

  /// 切换容器启停状态。参数：`{id: String, state: String}`
  static Future<Map<String, dynamic>> toggleContainerState(
      dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final state = arguments['state'] as String? ?? '';
      final service = ContainerService();
      if (state == 'running') {
        await service.stopContainer(id);
      } else {
        await service.startContainer(id);
      }
      return _ok();
    } catch (e) {
      appLogger.e('toggleContainerState failed: $e');
      return _err(e);
    }
  }

  /// 重启容器。参数：`{id: String}`
  static Future<Map<String, dynamic>> restartContainer(
      dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final service = ContainerService();
      await service.restartContainer(id);
      return _ok();
    } catch (e) {
      appLogger.e('restartContainer failed: $e');
      return _err(e);
    }
  }

  /// 删除容器。参数：`{id: String}`
  static Future<Map<String, dynamic>> deleteContainer(
      dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final service = ContainerService();
      await service.removeContainer(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainer failed: $e');
      return _err(e);
    }
  }

  // ── 应用 ────────────────────────────────────────────────────────────────

  /// 启动应用。参数：`{installId: int}`
  static Future<Map<String, dynamic>> startApp(dynamic arguments) async {
    try {
      final installId = _toInt(arguments['installId']);
      final service = AppService();
      await service.operateApp(installId, 'start');
      return _ok();
    } catch (e) {
      appLogger.e('startApp failed: $e');
      return _err(e);
    }
  }

  /// 停止应用。参数：`{installId: int}`
  static Future<Map<String, dynamic>> stopApp(dynamic arguments) async {
    try {
      final installId = _toInt(arguments['installId']);
      final service = AppService();
      await service.operateApp(installId, 'stop');
      return _ok();
    } catch (e) {
      appLogger.e('stopApp failed: $e');
      return _err(e);
    }
  }

  /// 更新应用。参数：`{installId: String}`
  static Future<Map<String, dynamic>> updateApp(dynamic arguments) async {
    try {
      final installId = arguments['installId'].toString();
      final service = AppService();
      await service.updateApp(installId);
      return _ok();
    } catch (e) {
      appLogger.e('updateApp failed: $e');
      return _err(e);
    }
  }

  /// 卸载应用。参数：`{installId: String}`
  static Future<Map<String, dynamic>> uninstallApp(dynamic arguments) async {
    try {
      final installId = arguments['installId'].toString();
      final service = AppService();
      await service.uninstallApp(installId);
      return _ok();
    } catch (e) {
      appLogger.e('uninstallApp failed: $e');
      return _err(e);
    }
  }

  /// 安装应用。参数：`{appDetailId, name, type, params?}`，
  /// 高级选项追加 `{containerName?, cpuQuota?, memoryLimit?, memoryUnit?, services?}`。
  static Future<Map<String, dynamic>> installApp(dynamic arguments) async {
    try {
      final appDetailId = _toInt(arguments['appDetailId']);
      final name = (arguments['name'] as String).trim();
      final type = arguments['type'] as String?;
      final params = (arguments['params'] as Map?)?.cast<String, dynamic>();
      final containerName = arguments['containerName'] as String?;
      final cpuQuotaRaw = arguments['cpuQuota'];
      final memoryLimitRaw = arguments['memoryLimit'];
      final memoryUnit = arguments['memoryUnit'] as String?;
      final services = (arguments['services'] as Map?)?.cast<String, String>();
      final service = AppService();
      await service.installApp(AppInstallCreateRequest(
        appDetailId: appDetailId,
        name: name,
        type: type,
        advanced: arguments['advanced'] as bool? ?? false,
        containerName: containerName,
        cpuQuota:
            cpuQuotaRaw == null ? null : double.tryParse(cpuQuotaRaw.toString()),
        memoryLimit: memoryLimitRaw == null
            ? null
            : double.tryParse(memoryLimitRaw.toString()),
        memoryUnit: memoryUnit,
        services: services,
        params: params,
        hostMode: false,
        allowPort: true,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('installApp failed: $e');
      return _err(e);
    }
  }

  // ── 文件 ────────────────────────────────────────────────────────────────

  /// 删除文件或目录。参数：`{path: String, isDir: bool?}`
  static Future<Map<String, dynamic>> deleteFile(dynamic arguments) async {
    try {
      final path = arguments['path'] as String;
      final isDir = arguments['isDir'] as bool?;
      final service = FileBrowserService();
      await service.deleteFiles([path], isDir: isDir);
      return _ok();
    } catch (e) {
      appLogger.e('deleteFile failed: $e');
      return _err(e);
    }
  }

  /// 创建目录。参数：`{path: String}`
  static Future<Map<String, dynamic>> createFolder(dynamic arguments) async {
    try {
      final path = arguments['path'] as String;
      final service = FileBrowserService();
      await service.createDirectory(path);
      return _ok();
    } catch (e) {
      appLogger.e('createFolder failed: $e');
      return _err(e);
    }
  }

  /// 重命名文件或目录。参数：`{oldPath: String, newPath: String}`
  static Future<Map<String, dynamic>> renameFile(dynamic arguments) async {
    try {
      final oldPath = arguments['oldPath'] as String;
      final newPath = arguments['newPath'] as String;
      final service = FileBrowserService();
      await service.renameFile(oldPath, newPath);
      return _ok();
    } catch (e) {
      appLogger.e('renameFile failed: $e');
      return _err(e);
    }
  }

  // ── 定时任务 ──────────────────────────────────────────────────────────────

  /// 切换定时任务启停。参数：`{id: int, currentStatus: String}`
  static Future<Map<String, dynamic>> toggleCronJobStatus(
      dynamic arguments) async {
    try {
      final id = _toInt(arguments['id']);
      final currentStatus = arguments['currentStatus'] as String? ?? '';
      final service = CronjobRepository();
      final newStatus = currentStatus == 'Enable' ? 'Disable' : 'Enable';
      await service.updateStatus(CronjobStatusUpdate(id: id, status: newStatus));
      return _ok();
    } catch (e) {
      appLogger.e('toggleCronJobStatus failed: $e');
      return _err(e);
    }
  }

  /// 删除定时任务。参数：`{id: int}`
  static Future<Map<String, dynamic>> deleteCronJob(dynamic arguments) async {
    try {
      final id = _toInt(arguments['id']);
      final service = CronjobRepository();
      await service.deleteById(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteCronJob failed: $e');
      return _err(e);
    }
  }

  // ── 备份 ─────────────────────────────────────────────────────────────────

  /// 删除备份记录。参数：`{id: int, name: String, type: String, status: String}`
  static Future<Map<String, dynamic>> deleteBackup(dynamic arguments) async {
    try {
      final record = BackupRecord(
        id: _toInt(arguments['id']),
        name: arguments['name'] as String? ?? '',
        type: arguments['type'] as String? ?? '',
        status: arguments['status'] as String? ?? '',
        size: 0,
      );
      final service = BackupRecordService();
      await service.deleteRecord(record);
      return _ok();
    } catch (e) {
      appLogger.e('deleteBackup failed: $e');
      return _err(e);
    }
  }

  // ── AI 模型 ──────────────────────────────────────────────────────────────

  /// 删除 Ollama 模型。参数：`{id: int}`
  static Future<Map<String, dynamic>> deleteAIModel(dynamic arguments) async {
    try {
      final id = _toInt(arguments['id']);
      final repository = AIRepository();
      await repository.deleteOllamaModel(ids: [id]);
      return _ok();
    } catch (e) {
      appLogger.e('deleteAIModel failed: $e');
      return _err(e);
    }
  }

  // ── 防火墙 ────────────────────────────────────────────────────────────────

  /// 添加防火墙端口规则。参数：`{port: String, protocol: String, address: String, strategy: String}`
  static Future<Map<String, dynamic>> addFirewallRule(dynamic arguments) async {
    try {
      final port = arguments['port'] as String? ?? '';
      final protocol = arguments['protocol'] as String? ?? 'tcp';
      final address = arguments['address'] as String? ?? '';
      final strategy = arguments['strategy'] as String? ?? 'accept';
      final service = FirewallService();
      if (port.isNotEmpty) {
        await service.createPortRule(FirewallPortRulePayload(
          operation: 'add',
          address: address,
          port: port,
          source: address,
          protocol: protocol,
          strategy: strategy,
        ));
      } else if (address.isNotEmpty) {
        await service.createIpRule(FirewallIpRulePayload(
          operation: 'add',
          address: address,
          strategy: strategy,
        ));
      }
      return _ok();
    } catch (e) {
      appLogger.e('addFirewallRule failed: $e');
      return _err(e);
    }
  }

  /// 删除防火墙规则。参数：`{port: String, protocol: String, address: String, strategy: String}`
  static Future<Map<String, dynamic>> deleteFirewallRule(
      dynamic arguments) async {
    try {
      final port = arguments['port'] as String? ?? '';
      final protocol = arguments['protocol'] as String? ?? '';
      final strategy = arguments['strategy'] as String? ?? '';
      final address = arguments['address'] as String? ?? '';
      final ruleType = port.isNotEmpty ? 'port' : 'address';
      final request = FirewallBatchRuleRequest(
        type: ruleType,
        rules: [
          {
            'port': port,
            'protocol': protocol,
            'strategy': strategy,
            'address': address,
          }
        ],
      );
      final service = FirewallService();
      await service.deleteRules(request);
      return _ok();
    } catch (e) {
      appLogger.e('deleteFirewallRule failed: $e');
      return _err(e);
    }
  }

  // ── 缓存 ──────────────────────────────────────────────────────────────────

  /// 清除 SharedPreferences 缓存（保留服务器配置等核心数据）。无参数。
  static Future<Map<String, dynamic>> clearCache(dynamic arguments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 只清除非核心缓存 key（保留 app_ui_render_mode、app_locale 等设置）
      final keysToRemove = prefs.getKeys().where((k) =>
          !k.startsWith('flutter.server_') &&
          !k.startsWith('flutter.app_ui_render_mode') &&
          !k.startsWith('flutter.app_locale'));
      for (final k in keysToRemove) {
        await prefs.remove(k);
      }
      return _ok();
    } catch (e) {
      appLogger.e('clearCache failed: $e');
      return _err(e);
    }
  }

  // ── 内部工具 ──────────────────────────────────────────────────────────────

  /// 将 dynamic 类型的 id 安全转换为 int（支持 int 和 String 输入）。
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return int.parse(value.toString());
  }
}
