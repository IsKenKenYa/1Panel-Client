import 'package:mime/mime.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'dart:convert';

import '../../features/alert/alert_service.dart';
import '../../features/alert/alert_types.dart';
import '../../features/runtimes/services/runtime_service.dart';
import '../../features/monitoring/monitoring_service.dart';
import '../../features/ai/model_downloader_service.dart';
import '../../data/models/setting_models.dart';
import '../../data/models/alert_models.dart';
import 'native_alert_payloads.dart';
import 'cronjob_operate_payload.dart';

import '../../features/ai/ai_repository.dart';
import '../../api/v2/file_v2.dart';
import '../../api/v2/website_v2.dart';
import '../../data/models/ai/agent_account_models.dart';
import '../../data/models/ai/agent_core_models.dart';
import '../../data/models/mcp_models.dart';
import '../../features/apps/app_service.dart';
import '../../features/commands/services/command_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../../features/group/services/group_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/containers/container_service.dart';
import '../../features/databases/databases_service.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../data/repositories/cronjob_form_repository.dart';
import '../../data/models/cronjob_form_request_models.dart';
import '../../data/repositories/database_repository.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/openresty/services/openresty_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/websites/services/website_certificate_service.dart';

import '../../features/toolbox/services/toolbox_device_service.dart';
import '../../features/vm/vm_service.dart';
import '../../data/models/vm/vm_resource_models.dart';
import '../../data/models/app_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_models.dart';
import '../../data/models/file_models.dart';
import '../../data/models/process_models.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/firewall/firewall_service.dart';
import '../../api/v2/firewall_v2.dart';
import '../../data/models/firewall_v2_models.dart';
import 'native_firewall_payloads.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../data/models/website_models.dart';
import '../../data/models/website_ssl_crud_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../core/config/api_config.dart';
import '../../core/config/debug_seed_config.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/backup_account_models.dart';
import '../../data/models/backup_request_models.dart';
import '../../data/models/database_models.dart';
import '../../data/models/firewall_models.dart';
import '../../core/services/app_preferences_service.dart';
import '../../core/theme/ui_render_mode.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/backups/services/backup_recover_service.dart';
import '../config/api_constants.dart';
import 'native_server_config.dart';
import '../network/api_client_manager.dart';
import '../services/cache/file_preview_cache_manager.dart';
import '../services/logger/logger_service.dart';
import 'dart:ui' show Locale;

/// 统一返回结构：成功 `{success: true}`，失败 `{success: false, error: String}`。
Map<String, dynamic> _ok() => {'success': true};
Map<String, dynamic> _err(Object e) => {'success': false, 'error': e.toString()};

/// B1 网站配置中心写通道使用的网站 V2 API（按需构造）。
Future<WebsiteV2Api> _websiteApi() async =>
    WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());

/// B2 文件管理深度写通道使用的文件 V2 API（按需构造）。
Future<FileV2Api> _fileApi() async =>
    FileV2Api(await ApiClientManager.instance.getCurrentClient());

/// 所有 Native Channel 写操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelWriteHandlers {
  static Future<Map<String, dynamic>> remoteDatabaseUnbind(
    dynamic arguments, {
    required bool confirm,
  }) async {
    final id = arguments?['id'];
    final serverId = arguments?['serverId'];
    if (id is! int || id < 1 || serverId is! String || serverId.isEmpty) {
      return _err(ArgumentError('Invalid remote database identity'));
    }
    try {
      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null || config.id != serverId) {
        return {'success': false, 'serverChanged': true};
      }
      final service = DatabasesService(
        repository: DatabaseRepository(config: config),
      );
      final dependentApps = confirm
          ? await service.unbindRemoteDatabase(id)
          : await service.checkRemoteDatabaseUnbind(id);
      return {
        'success': !confirm || dependentApps.isEmpty,
        'dependentApps': dependentApps,
      };
    } catch (error, stackTrace) {
      appLogger.eWithPackage('core.channel.remote_database', 'Unbind failed',
          error: error, stackTrace: stackTrace);
      return _err(error);
    }
  }

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

  /// 新增指定面板类型的服务器配置。
  static Future<Map<String, dynamic>> addServer(dynamic arguments) async {
    try {
      final id = 'server_${DateTime.now().microsecondsSinceEpoch}';
      final config = readNativeServerConfig(arguments as Map, id: id);
      final repository = const ServerRepository();
      await repository.saveConfig(config);
      return {'success': true, 'id': id};
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

  /// 使用编辑表单打开时的 revision 更新服务器配置。
  static Future<Map<String, dynamic>> updateServer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      final existing = await ApiConfigManager.getConfig(id);
      final updated = readNativeServerConfig(
        arguments as Map,
        id: id,
        existing: existing,
      );
      await const ServerRepository().updateConfig(updated, expected: existing);
      return _ok();
    } catch (e) {
      appLogger.e('updateServer failed: $e');
      return _err(e);
    }
  }

  // ── 网站 ────────────────────────────────────────────────────────────────

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

  // ── 网站配置中心（B1）───────────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b1_website_channel_contract.md。
  // 写语义：成功 `{success: true}`，失败 `{success: false, error}`；
  // 必填参数缺失时快速失败，不发出请求。

  /// 网站 HTTPS 配置。参数：
  /// `{websiteId: int, enable: bool, websiteSSLId?: int, type: 'existed'|'manual',
  ///   certificate?: String, privateKey?: String, httpConfig: String,
  ///   sslProtocol: [String], algorithm: String, hsts?: bool,
  ///   hstsIncludeSubDomains?: bool, http3?: bool}`
  /// POST /websites/{websiteId}/https（sslProtocol 映射为服务端 SSLProtocol）。
  static Future<Map<String, dynamic>> updateWebsiteHttpsConfig(
      dynamic arguments) async {
    try {
      final websiteId =
          int.tryParse('${arguments['websiteId'] ?? arguments['websiteID'] ?? ''}');
      if (websiteId == null) {
        return {'success': false, 'error': 'websiteId is required'};
      }
      await (await _websiteApi()).updateWebsiteHttps(
        websiteId: websiteId,
        request: WebsiteHttpsUpdateRequest(
          websiteId: websiteId,
          enable: arguments['enable'] as bool?,
          type: arguments['type'] as String?,
          websiteSSLId: int.tryParse('${arguments['websiteSSLId'] ?? ''}'),
          certificate: arguments['certificate'] as String?,
          privateKey: arguments['privateKey'] as String?,
          httpConfig: arguments['httpConfig'] as String?,
          sslProtocol:
              (arguments['sslProtocol'] as List?)?.whereType<String>().toList(),
          algorithm: arguments['algorithm'] as String?,
          hsts: arguments['hsts'] as bool?,
          hstsIncludeSubDomains: arguments['hstsIncludeSubDomains'] as bool?,
          http3: arguments['http3'] as bool?,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteHttpsConfig failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _proxyOperates = {'create', 'edit'};

  /// 网站反向代理建/改。参数（全部扁平）：
  /// `{websiteID: int, operate: 'create'|'edit', name: String, match: String,
  ///   proxyProtocol: String, proxyAddress: String, proxyHost?: String,
  ///   sni?: bool, proxySSLName?, sslVerify?: bool, cache?: bool,
  ///   serverCacheTime?: int, serverCacheUnit?: String, browserCache?: String,
  ///   cacheTime?: int, cacheUnit?: String, cors?: bool, allowOrigins?: String,
  ///   allowMethods?: String, allowHeaders?: String, allowCredentials?: bool,
  ///   preflight?: bool}`
  /// POST /websites/proxies/update。
  /// 上游前端保存语义（proxy/create/index.vue）：
  /// proxyPass = proxyProtocol + proxyAddress，缺省字段取上游 initData 默认值。
  /// WebsiteV2Api.updateWebsiteProxy 签名为 (websiteId, name, content)，与
  /// 契约扁平结构体不匹配（服务端吃完整 WebsiteProxyConfig），故按上游形状
  /// 直发，website_v2.dart 不改动。
  static Future<Map<String, dynamic>> updateWebsiteProxy(
      dynamic arguments) async {
    try {
      final operate = (arguments['operate'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      final match = (arguments['match'] as String? ?? '').trim();
      final proxyAddress = (arguments['proxyAddress'] as String? ?? '').trim();
      if (!_proxyOperates.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operate: $operate'};
      }
      if (name.isEmpty || match.isEmpty || proxyAddress.isEmpty) {
        return {'success': false,
            'error': 'name, match and proxyAddress are required'};
      }
      final proxyProtocol =
          (arguments['proxyProtocol'] as String? ?? 'http://').trim();
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/websites/proxies/update'),
        data: {
          'id': int.tryParse('${arguments['id'] ?? 0}') ?? 0,
          'operate': operate,
          // 契约未携带 enable：与上游 initData 一致默认开启。
          'enable': arguments['enable'] ?? true,
          'name': name,
          'match': match,
          'proxyPass': '$proxyProtocol$proxyAddress',
          'proxyProtocol': proxyProtocol,
          'proxyAddress': proxyAddress,
          'proxyHost': arguments['proxyHost'] ?? r'$host',
          'sni': arguments['sni'] ?? false,
          // 服务端 ProxySSLName 为 string；契约声明 bool——原样透传不转类型。
          'proxySSLName': arguments['proxySSLName'] ?? '',
          'sslVerify': arguments['sslVerify'] ?? false,
          'cache': arguments['cache'] ?? false,
          'cacheTime': int.tryParse('${arguments['cacheTime'] ?? 0}') ?? 0,
          'cacheUnit': arguments['cacheUnit'] ?? '',
          'serverCacheTime':
              int.tryParse('${arguments['serverCacheTime'] ?? 10}') ?? 10,
          'serverCacheUnit': arguments['serverCacheUnit'] ?? 'm',
          'browserCache': arguments['browserCache'] ?? 'noModify',
          'cors': arguments['cors'] ?? false,
          'allowOrigins': arguments['allowOrigins'] ?? '*',
          'allowMethods':
              arguments['allowMethods'] ?? 'GET,POST,OPTIONS,PUT,DELETE',
          'allowHeaders': arguments['allowHeaders'] ?? '',
          'allowCredentials': arguments['allowCredentials'] ?? false,
          'preflight': arguments['preflight'] ?? true,
          'modifier': '',
          'filePath': '',
          'replaces': <String, dynamic>{},
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteProxy failed: $e');
      return _err(e);
    }
  }

  /// 删除网站反向代理。参数：`{id: int, name: String}`。POST /websites/proxies/delete。
  static Future<Map<String, dynamic>> deleteWebsiteProxy(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      if (id == null || name.isEmpty) {
        return {'success': false, 'error': 'id and name are required'};
      }
      await (await _websiteApi())
          .deleteWebsiteProxy({'id': id, 'name': name});
      return _ok();
    } catch (e) {
      appLogger.e('deleteWebsiteProxy failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _proxyStatuses = {'enable', 'disable'};

  /// 网站反向代理启停。参数：
  /// `{id: int, name: String, status: 'enable'|'disable'}`。POST /websites/proxies/status。
  static Future<Map<String, dynamic>> updateWebsiteProxyStatus(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      final status = (arguments['status'] as String? ?? '').trim();
      if (id == null || name.isEmpty) {
        return {'success': false, 'error': 'id and name are required'};
      }
      if (!_proxyStatuses.contains(status)) {
        return {'success': false, 'error': 'Unsupported status: $status'};
      }
      await (await _websiteApi())
          .updateWebsiteProxyStatus({'id': id, 'name': name, 'status': status});
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteProxyStatus failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _redirectOperates = {
    'create', 'edit', 'delete', 'enable', 'disable',
  };

  /// 网站重定向操作。参数（全部扁平）：
  /// `{websiteID: int, operate: 'create'|'edit'|'delete'|'enable'|'disable',
  ///   enable: bool, name: String, keepPath?: bool, type: 'domain'|'path'|'404',
  ///   redirect: '301'|'302', path?: String, target?: String, domains?: [String]}`
  /// POST /websites/redirect/update（键名与服务端 NginxRedirectReq 一致）。
  static Future<Map<String, dynamic>> updateWebsiteRedirect(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final operate = (arguments['operate'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      if (!_redirectOperates.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operate: $operate'};
      }
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await (await _websiteApi()).updateWebsiteRedirectConfig({
        'websiteID': websiteID,
        'operate': operate,
        'enable': arguments['enable'] ?? false,
        'name': name,
        if (arguments['keepPath'] != null) 'keepPath': arguments['keepPath'],
        'type': arguments['type'] as String? ?? '',
        'redirect': arguments['redirect'] as String? ?? '',
        if (arguments['redirectRoot'] != null)
          'redirectRoot': arguments['redirectRoot'],
        if (arguments['path'] != null) 'path': arguments['path'],
        if (arguments['target'] != null) 'target': arguments['target'],
        if (arguments['domains'] is List)
          'domains': (arguments['domains'] as List)
              .map((e) => '$e')
              .toList(),
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteRedirect failed: $e');
      return _err(e);
    }
  }

  /// 网站伪静态保存。参数：
  /// `{websiteID: int, name: String, content: String}`。POST /websites/rewrite/update。
  static Future<Map<String, dynamic>> updateWebsiteRewrite(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await (await _websiteApi()).updateWebsiteRewrite(
        websiteId: websiteID,
        name: name,
        content: arguments['content'] as String? ?? '',
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteRewrite failed: $e');
      return _err(e);
    }
  }

  /// 网站 CORS 配置。参数：
  /// `{websiteID: int, cors: bool, allowOrigins: String, allowMethods: String,
  ///   allowHeaders?: String, allowCredentials?: bool, preflight?: bool}`
  /// POST /websites/cors/update（键名与服务端 CorsConfigReq 一致）。
  static Future<Map<String, dynamic>> updateWebsiteCors(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      await (await _websiteApi()).updateWebsiteCorsConfig({
        'websiteID': websiteID,
        'cors': arguments['cors'] ?? false,
        'allowOrigins': arguments['allowOrigins'] as String? ?? '',
        'allowMethods': arguments['allowMethods'] as String? ?? '',
        'allowHeaders': arguments['allowHeaders'] as String? ?? '',
        'allowCredentials': arguments['allowCredentials'] ?? false,
        'preflight': arguments['preflight'] ?? false,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteCors failed: $e');
      return _err(e);
    }
  }

  /// 网站防盗链配置。参数：
  /// `{websiteID: int, enable: bool, extends: String, serverNames: [String],
  ///   noneRef?: bool, blocked?: bool, return_: '400'|'403'|'404', cache?: bool,
  ///   cacheTime?: int, cacheUint?: String, logEnable?: bool}`
  /// POST /websites/leech/update。`return` 是 Dart 保留字：参数键 `return_`
  /// 映射回服务端键 `return`；`cacheUint` 为上游既有拼写，原样保留。
  static Future<Map<String, dynamic>> updateWebsiteLeech(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      await (await _websiteApi()).updateWebsiteLeechConfig({
        'websiteID': websiteID,
        'enable': arguments['enable'] ?? false,
        'extends': arguments['extends'] as String? ?? '',
        'serverNames': (arguments['serverNames'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const <String>[],
        'noneRef': arguments['noneRef'] ?? false,
        'blocked': arguments['blocked'] ?? false,
        'return': arguments['return_'] as String? ?? '',
        'cache': arguments['cache'] ?? false,
        'cacheTime': int.tryParse('${arguments['cacheTime'] ?? 0}') ?? 0,
        'cacheUint': arguments['cacheUint'] as String? ?? '',
        'logEnable': arguments['logEnable'] ?? false,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteLeech failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _authOperates = {
    'create', 'edit', 'delete', 'enable', 'disable',
  };

  /// 网站 BasicAuth 操作。参数：
  /// `{websiteID: int, operate: 'create'|'edit'|'delete'|'enable'|'disable',
  ///   scope: 'root', username?: String, password?: String, remark?: String}`
  /// POST /websites/auths/update。
  static Future<Map<String, dynamic>> updateWebsiteAuth(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final operate = (arguments['operate'] as String? ?? '').trim();
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      if (!_authOperates.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operate: $operate'};
      }
      await (await _websiteApi()).updateWebsiteAuthConfig({
        'websiteID': websiteID,
        'operate': operate,
        'scope': arguments['scope'] as String? ?? 'root',
        'username': arguments['username'] as String? ?? '',
        'password': arguments['password'] as String? ?? '',
        'remark': arguments['remark'] as String? ?? '',
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteAuth failed: $e');
      return _err(e);
    }
  }

  /// 网站反向代理缓存配置。参数：
  /// `{websiteID: int, open: bool, cacheLimit: int, cacheLimitUnit: String,
  ///   shareCache: int, shareCacheUnit: String, cacheExpire: int,
  ///   cacheExpireUnit: String}`。POST /websites/proxy/config。
  static Future<Map<String, dynamic>> updateWebsiteProxyCache(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      final cacheLimit = _boundedInt(arguments['cacheLimit'], 'cacheLimit');
      final shareCache = _boundedInt(arguments['shareCache'], 'shareCache');
      final cacheExpire = _boundedInt(arguments['cacheExpire'], 'cacheExpire');
      if (cacheLimit == null || shareCache == null || cacheExpire == null) {
        return {
          'success': false,
          'error': 'cacheLimit, shareCache and cacheExpire are required',
        };
      }
      await (await _websiteApi()).updateWebsiteProxyCacheConfig({
        'websiteID': websiteID,
        'open': arguments['open'] ?? false,
        'cacheLimit': cacheLimit,
        'cacheLimitUnit': arguments['cacheLimitUnit'] as String? ?? 'g',
        'shareCache': shareCache,
        'shareCacheUnit': arguments['shareCacheUnit'] as String? ?? 'm',
        'cacheExpire': cacheExpire,
        'cacheExpireUnit': arguments['cacheExpireUnit'] as String? ?? 'h',
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteProxyCache failed: $e');
      return _err(e);
    }
  }

  /// 清理网站代理缓存。参数：`{id: int 必填}`。POST /websites/proxy/clear。
  static Future<Map<String, dynamic>> clearWebsiteProxyCache(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['id'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await (await _websiteApi())
          .clearWebsiteProxyCache({'websiteID': websiteID});
      return _ok();
    } catch (e) {
      appLogger.e('clearWebsiteProxyCache failed: $e');
      return _err(e);
    }
  }

  /// 网站真实 IP 配置。参数：
  /// `{websiteID: int, open: bool, ipFrom: String, ipHeader: String,
  ///   ipOther: String}`。POST /websites/realip/config。
  static Future<Map<String, dynamic>> updateWebsiteRealIP(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      final open = arguments['open'] == true;
      final ipFrom = (arguments['ipFrom'] as String? ?? '').trim();
      final ipHeader = (arguments['ipHeader'] as String? ?? '').trim();
      final ipOther = (arguments['ipOther'] as String? ?? '').trim();
      if (open && ipFrom.isEmpty) {
        return {'success': false, 'error': 'ipFrom is required'};
      }
      if (open && ipHeader.isEmpty) {
        return {'success': false, 'error': 'ipHeader is required'};
      }
      if (open && ipHeader == 'other' && ipOther.isEmpty) {
        return {'success': false, 'error': 'ipOther is required'};
      }
      await (await _websiteApi()).updateWebsiteRealIpConfig({
        'websiteID': websiteID,
        'open': open,
        'ipFrom': ipFrom.isEmpty ? '127.0.0.1' : ipFrom,
        'ipHeader': ipHeader.isEmpty ? 'X-Real-IP' : ipHeader,
        'ipOther': ipOther,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteRealIP failed: $e');
      return _err(e);
    }
  }

  /// 网站 TCP/UDP 转发配置。参数：
  /// `{websiteID: int, streamPorts: String, udp: bool, name: String,
  ///   algorithm: String, servers: [Map]}`。POST /websites/stream/update。
  static Future<Map<String, dynamic>> updateWebsiteStream(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      final streamPorts = (arguments['streamPorts'] as String? ?? '').trim();
      if (streamPorts.isEmpty) {
        return {'success': false, 'error': 'streamPorts is required'};
      }
      await (await _websiteApi()).updateWebsiteStreamConfig({
        'websiteID': websiteID,
        'streamPorts': streamPorts,
        'udp': arguments['udp'] == true,
        'name': arguments['name'] as String? ?? '',
        'algorithm': arguments['algorithm'] as String? ?? '',
        'servers': (arguments['servers'] as List?)
                ?.whereType<Map>()
                .map((server) => server.cast<String, dynamic>())
                .toList() ??
            const <Map<String, dynamic>>[],
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteStream failed: $e');
      return _err(e);
    }
  }

  /// 新建网站负载均衡。参数：
  /// `{websiteID: int, name: String, algorithm: String, servers: List<Map>}`。
  /// POST /websites/lbs/create。
  static Future<Map<String, dynamic>> createWebsiteLoadBalancer(
      dynamic arguments) {
    return _submitWebsiteLoadBalancer(arguments, update: false);
  }

  /// 修改网站负载均衡。参数同新建。POST /websites/lbs/update。
  static Future<Map<String, dynamic>> updateWebsiteLoadBalancer(
      dynamic arguments) {
    return _submitWebsiteLoadBalancer(arguments, update: true);
  }

  /// 删除网站负载均衡。参数：`{websiteID: int, name: String}`。
  /// POST /websites/lbs/del。
  static Future<Map<String, dynamic>> deleteWebsiteLoadBalancer(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      if (websiteID == null || name.isEmpty) {
        return {'success': false, 'error': 'websiteID and name are required'};
      }
      await (await _websiteApi())
          .deleteWebsiteLoadBalancer({'websiteID': websiteID, 'name': name});
      return _ok();
    } catch (e) {
      appLogger.e('deleteWebsiteLoadBalancer failed: $e');
      return _err(e);
    }
  }

  /// 修改负载均衡源文件。参数：
  /// `{websiteID: int, name: String, content: String}`。POST /websites/lbs/file。
  /// 服务端要求 name 为不含路径分段的文件名。
  static Future<Map<String, dynamic>> updateWebsiteLoadBalancerFile(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      final content = arguments['content'] as String? ?? '';
      if (websiteID == null || name.isEmpty || content.trim().isEmpty) {
        return {
          'success': false,
          'error': 'websiteID, name and content are required',
        };
      }
      if (name.contains('/') || name.contains('..')) {
        return {'success': false, 'error': 'name must be a plain file name'};
      }
      await (await _websiteApi()).updateWebsiteLoadBalancerFile({
        'websiteID': websiteID,
        'name': name,
        'content': content,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsiteLoadBalancerFile failed: $e');
      return _err(e);
    }
  }

  static Future<Map<String, dynamic>> _submitWebsiteLoadBalancer(
    dynamic arguments, {
    required bool update,
  }) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final name = (arguments['name'] as String? ?? '').trim();
      final algorithm = (arguments['algorithm'] as String? ?? '').trim();
      if (websiteID == null || name.isEmpty || algorithm.isEmpty) {
        return {
          'success': false,
          'error': 'websiteID, name and algorithm are required',
        };
      }
      if (!_loadBalancerAlgorithms.contains(algorithm)) {
        return {'success': false, 'error': 'Unsupported algorithm: $algorithm'};
      }
      final servers = _loadBalancerServers(arguments['servers']);
      if (servers == null || servers.isEmpty) {
        return {'success': false, 'error': 'servers are required'};
      }
      if (algorithm == 'ip_hash' &&
          servers.any((server) => server['flag'] == 'backup')) {
        return {
          'success': false,
          'error': 'ip_hash does not support backup servers',
        };
      }
      final payload = <String, dynamic>{
        'websiteID': websiteID,
        'name': name,
        'algorithm': algorithm,
        'servers': servers,
      };
      final api = await _websiteApi();
      if (update) {
        await api.updateWebsiteLoadBalancer(payload);
      } else {
        await api.createWebsiteLoadBalancer(payload);
      }
      return _ok();
    } catch (e) {
      appLogger.e('submitWebsiteLoadBalancer failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _loadBalancerAlgorithms = {
    'default',
    'ip_hash',
    'least_conn',
  };

  static const Set<String> _loadBalancerFlags = {'', 'down', 'backup'};

  static List<Map<String, dynamic>>? _loadBalancerServers(Object? raw) {
    if (raw is! List) return null;
    final servers = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map) return null;
      final server = (entry['server'] as String? ?? '').trim();
      final weight = _loadBalancerInt(entry['weight'], 100);
      final maxFails = _loadBalancerInt(entry['maxFails'], 1000);
      final maxConns = _loadBalancerInt(entry['maxConns'], 10000);
      final failTimeout = _loadBalancerInt(entry['failTimeout'], 300);
      final unit = (entry['failTimeoutUnit'] as String? ?? 's').trim();
      final flag = (entry['flag'] as String? ?? '').trim();
      if (server.isEmpty ||
          weight == null ||
          maxFails == null ||
          maxConns == null ||
          failTimeout == null ||
          !_loadBalancerFlags.contains(flag)) {
        return null;
      }
      servers.add(<String, dynamic>{
        'server': server,
        'weight': weight,
        'maxFails': maxFails,
        'maxConns': maxConns,
        'failTimeout': failTimeout,
        'failTimeoutUnit': unit.isEmpty ? 's' : unit,
        'flag': flag,
      });
    }
    return servers;
  }

  static int? _loadBalancerInt(Object? value, int max) {
    if (value == null || '$value'.trim().isEmpty) return 0;
    final parsed = int.tryParse('$value');
    if (parsed == null || parsed < 0 || parsed > max) return null;
    return parsed;
  }

  static int? _boundedInt(Object? value, String field) {
    final parsed = int.tryParse('$value');
    if (parsed == null || parsed < 0 || parsed > 9999) {
      return null;
    }
    return parsed;
  }

  static const Set<String> _pathAuthOperates = {'create', 'edit', 'delete'};

  /// 网站路径 BasicAuth 操作。参数：
  /// `{websiteID: int, operate: 'create'|'edit'|'delete', path?: String,
  ///   username?: String, password?: String, name?: String}`
  /// POST /websites/auths/path/update。
  static Future<Map<String, dynamic>> updateWebsitePathAuth(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      final operate = (arguments['operate'] as String? ?? '').trim();
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      if (!_pathAuthOperates.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operate: $operate'};
      }
      await (await _websiteApi()).updateWebsitePathAuthConfig({
        'websiteID': websiteID,
        'operate': operate,
        'path': arguments['path'] as String? ?? '',
        'username': arguments['username'] as String? ?? '',
        'password': arguments['password'] as String? ?? '',
        'name': arguments['name'] as String? ?? '',
        'remark': arguments['remark'] as String? ?? '',
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateWebsitePathAuth failed: $e');
      return _err(e);
    }
  }

  /// 网站追加域名。参数：
  /// `{websiteID: int, domains: [{domain: String, port: int, ssl: bool}]}`
  /// POST /websites/domains。
  static Future<Map<String, dynamic>> addWebsiteDomains(
      dynamic arguments) async {
    try {
      final websiteID = int.tryParse('${arguments['websiteID'] ?? ''}');
      if (websiteID == null) {
        return {'success': false, 'error': 'websiteID is required'};
      }
      final rawDomains = arguments['domains'];
      if (rawDomains is! List || rawDomains.isEmpty) {
        return {'success': false, 'error': 'domains is required'};
      }
      await (await _websiteApi()).addWebsiteDomains(
        websiteId: websiteID,
        domains: rawDomains
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
      return _ok();
    } catch (e) {
      appLogger.e('addWebsiteDomains failed: $e');
      return _err(e);
    }
  }

  /// 删除网站域名。参数：`{id: int}`。POST /websites/domains/del。
  static Future<Map<String, dynamic>> deleteWebsiteDomain(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await (await _websiteApi()).deleteWebsiteDomain(id: id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteWebsiteDomain failed: $e');
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

  /// 启动容器。参数：`{id: String}`
  static Future<Map<String, dynamic>> startContainer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      await ContainerService().startContainer(id);
      return _ok();
    } catch (e) {
      appLogger.e('startContainer failed: $e');
      return _err(e);
    }
  }

  /// 停止容器。参数：`{id: String}`
  static Future<Map<String, dynamic>> stopContainer(dynamic arguments) async {
    try {
      final id = arguments['id'] as String;
      await ContainerService().stopContainer(id);
      return _ok();
    } catch (e) {
      appLogger.e('stopContainer failed: $e');
      return _err(e);
    }
  }

  /// 新建容器。参数：
/// `{image: String, name: String, env?: [String], exposedPorts?: [{containerPort, hostPort?, hostIP?, protocol?}],
///   volumes?: [{sourceDir, containerDir, mode?, type?}], networks?: [String],
///   restartPolicy?: String, autoRemove?, privileged?, publishAllPorts?, tty?, openStdin?, forcePull?}`
  static Future<Map<String, dynamic>> createContainer(dynamic arguments) async {
    try {
      final image = (arguments['image'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      if (image.isEmpty || name.isEmpty) {
        return {'success': false, 'error': 'image and name are required'};
      }
      final taskID = DateTime.now().millisecondsSinceEpoch.toString();
      final body = <String, dynamic>{
        'image': image,
        'name': name,
        'taskID': taskID,
      };
      if (arguments['env'] is List) {
        body['env'] = (arguments['env'] as List).map((e) => '$e').toList();
      }
      if (arguments['exposedPorts'] is List) {
        body['exposedPorts'] = (arguments['exposedPorts'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      if (arguments['volumes'] is List) {
        body['volumes'] = (arguments['volumes'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      if (arguments['networks'] is List &&
          (arguments['networks'] as List).isNotEmpty) {
        body['networks'] = (arguments['networks'] as List)
            .map((e) => e is Map ? {'network': '${e['network'] ?? ''}'} : {'network': '$e'})
            .toList();
      } else {
        // 服务端创建容器要求显式网络，缺省使用 bridge。
        body['networks'] = [
          {'network': 'bridge'},
        ];
      }
      if (arguments['cmd'] is List) {
        body['cmd'] = (arguments['cmd'] as List).map((e) => '$e').toList();
      }
      for (final key in <String>[
        'restartPolicy',
        'autoRemove',
        'privileged',
        'publishAllPorts',
        'tty',
        'openStdin',
        'forcePull',
        'hostname',
      ]) {
        if (arguments[key] != null) {
          body[key] = arguments[key];
        }
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers'),
        data: body,
      );
      return _ok();
    } catch (e) {
      appLogger.e('createContainer failed: $e');
      return _err(e);
    }
  }

  /// 构建镜像。参数：
/// `{name: String, from: 'path'|'edit', dockerfile: String, tags?: [String], args?: [String]}`
  /// 服务端 dto.ImageBuild 要求 from/name/dockerfile，返回任务编号供任务日志查看。
  static Future<Map<String, dynamic>> buildContainerImage(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final from = (arguments['from'] as String? ?? 'path').trim();
      final dockerfile = arguments['dockerfile'] as String? ?? '';
      if (name.isEmpty || from.isEmpty || dockerfile.trim().isEmpty) {
        return {
          'success': false,
          'error': 'name, from and dockerfile are required',
        };
      }
      final taskID = DateTime.now().millisecondsSinceEpoch.toString();
      final body = <String, dynamic>{
        'from': from,
        'name': name,
        'dockerfile': dockerfile,
        'taskID': taskID,
      };
      if (arguments['tags'] is List) {
        body['tags'] = (arguments['tags'] as List).map((e) => '$e').toList();
      }
      if (arguments['args'] is List) {
        body['args'] = (arguments['args'] as List).map((e) => '$e').toList();
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/image/build'),
        data: body,
      );
      return {'success': true, 'taskId': taskID};
    } catch (e) {
      appLogger.e('buildContainerImage failed: $e');
      return _err(e);
    }
  }

  /// 推送镜像到仓库。参数：`{image: String, name: String, repository: String}`。
  /// 服务端 dto.ImagePush 以 tagName 作为本地源镜像引用，以 name 作为仓库内目标名。
  static Future<Map<String, dynamic>> pushContainerImage(
      dynamic arguments) async {
    try {
      final image = (arguments['image'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      final repository = (arguments['repository'] as String? ?? '').trim();
      if (image.isEmpty || name.isEmpty || repository.isEmpty) {
        return {
          'success': false,
          'error': 'image, name and repository are required',
        };
      }
      final api = await ApiClientManager.instance.getContainerApi();
      final repos = (await api.getRepos()).data ?? const <ContainerRepo>[];
      final repo = repos.firstWhere(
        (item) => '${item.id}' == repository || item.name == repository,
        orElse: () => throw StateError('repository not found: $repository'),
      );
      final taskID = DateTime.now().millisecondsSinceEpoch.toString();
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/image/push'),
        data: {
          'name': name,
          'repoID': repo.id,
          'tagName': image,
          'taskID': taskID,
        },
      );
      return {'success': true, 'taskId': taskID};
    } catch (e) {
      appLogger.e('pushContainerImage failed: $e');
      return _err(e);
    }
  }

  /// 新建镜像仓库。参数：`{name, downloadUrl, username?, password?}`
  static Future<Map<String, dynamic>> createContainerRepo(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final downloadUrl = (arguments['downloadUrl'] as String? ?? '').trim();
      if (name.isEmpty || downloadUrl.isEmpty) {
        return {'success': false, 'error': 'name and downloadUrl are required'};
      }
      await (await ApiClientManager.instance.getContainerApi()).createRepo(
        ContainerRepoOperate(
          name: name,
          downloadUrl: downloadUrl,
          username: arguments['username'] as String?,
          password: arguments['password'] as String?,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createContainerRepo failed: $e');
      return _err(e);
    }
  }

  /// 删除镜像仓库。参数：`{id: int}`。
  static Future<Map<String, dynamic>> deleteContainerRepo(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/repo/del'),
        data: {'id': id},
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainerRepo failed: $e');
      return _err(e);
    }
  }

  /// 新建编排模版。参数：`{name, description?, content}`。
  static Future<Map<String, dynamic>> createContainerTemplate(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final content = arguments['content'] as String? ?? '';
      if (name.isEmpty || content.trim().isEmpty) {
        return {'success': false, 'error': 'name and content are required'};
      }
      await (await ApiClientManager.instance.getContainerApi()).createTemplate(
        ContainerTemplateOperate(
          name: name,
          description: arguments['description'] as String? ?? '',
          content: content,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createContainerTemplate failed: $e');
      return _err(e);
    }
  }

  /// 删除编排模版。参数：`{id: int}`。
  static Future<Map<String, dynamic>> deleteContainerTemplate(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/template/del'),
        data: {
          'ids': [id],
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainerTemplate failed: $e');
      return _err(e);
    }
  }

  /// 停止监听端口进程。参数：`{pid: int}`。POST /process/stop。
  static Future<Map<String, dynamic>> stopListeningProcess(
      dynamic arguments) async {
    try {
      final pid = int.tryParse('${arguments['pid'] ?? ''}');
      if (pid == null) {
        return {'success': false, 'error': 'pid is required'};
      }
      await (await ApiClientManager.instance.getProcessApi())
          .stopProcess(ProcessStopRequest(pid: pid));
      return _ok();
    } catch (e) {
      appLogger.e('stopListeningProcess failed: $e');
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

  /// 删除镜像。参数：`{id: String}`。上游按 `names` 数组 + taskID 定位。
  static Future<Map<String, dynamic>> deleteContainerImage(
      dynamic arguments) async {
    try {
      final id = (arguments['id'] as String? ?? '').trim();
      if (id.isEmpty) {
        return {'success': false, 'error': 'id is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/image/remove'),
        data: {
          'names': [id],
          'taskID': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainerImage failed: $e');
      return _err(e);
    }
  }

  /// 拉取镜像。参数：`{image: String, tag?: String}`。
  /// POST /containers/image/pull。
  static Future<Map<String, dynamic>> pullContainerImage(
      dynamic arguments) async {
    try {
      final image = (arguments['image'] as String? ?? '').trim();
      if (image.isEmpty) {
        return {'success': false, 'error': 'image is required'};
      }
      await OrchestrationService().pullImage(
        ImagePull(
          image: image,
          tag: (arguments['tag'] as String? ?? '').trim().isEmpty
              ? null
              : (arguments['tag'] as String).trim(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('pullContainerImage failed: $e');
      return _err(e);
    }
  }

  /// 删除网络。参数：`{name: String}`。
  static Future<Map<String, dynamic>> deleteContainerNetwork(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/network/del'),
        data: {
          'names': [name],
          'taskID': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainerNetwork failed: $e');
      return _err(e);
    }
  }

  /// 创建网络。参数：`{name: String, driver?: String, subnet?: String, gateway?: String}`。
  static Future<Map<String, dynamic>> createContainerNetwork(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      final payload = <String, dynamic>{
        'name': name,
        'driver': arguments['driver'] as String? ?? 'bridge',
        'ipv4': true,
      };
      final subnet = (arguments['subnet'] as String? ?? '').trim();
      if (subnet.isNotEmpty) payload['subnet'] = subnet;
      final gateway = (arguments['gateway'] as String? ?? '').trim();
      if (gateway.isNotEmpty) payload['gateway'] = gateway;
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/network'),
        data: payload,
      );
      return _ok();
    } catch (e) {
      appLogger.e('createContainerNetwork failed: $e');
      return _err(e);
    }
  }

  /// 删除存储卷。参数：`{name: String}`。
  static Future<Map<String, dynamic>> deleteContainerVolume(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/volume/del'),
        data: {
          'names': [name],
          'taskID': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteContainerVolume failed: $e');
      return _err(e);
    }
  }

  /// 创建存储卷。参数：`{name: String, driver?: String}`。
  static Future<Map<String, dynamic>> createContainerVolume(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/volume'),
        data: {
          'name': name,
          'driver': arguments['driver'] as String? ?? 'local',
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('createContainerVolume failed: $e');
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

  /// 重启应用。参数：`{installId: int}`
  static Future<Map<String, dynamic>> restartApp(dynamic arguments) async {
    try {
      final installId = _toInt(arguments['installId']);
      final service = AppService();
      await service.operateApp(installId, 'restart');
      return _ok();
    } catch (e) {
      appLogger.e('restartApp failed: $e');
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

  /// 安装应用商店应用（WinUI3 首个场景：OpenResty）。
  /// 两种参数形态：
  /// - `{appKey, version?, name?}`：按 appKey 解析到 detail 再安装，
  ///   params 取表单字段默认值（等价对话框 _paramControllers 初始化语义）。
  /// - `{appDetailId, name, type, params?, containerName?, cpuQuota?,
  ///    memoryLimit?, memoryUnit?, services?}`：直接按 detail id 安装，
  ///   高级选项直传（iOS 走查批次行级对齐的调用形态）。
  /// 返回：`{success: true, appId: <安装返回 id 或 0>}`。
  static Future<Map<String, dynamic>> installApp(dynamic arguments) async {
    try {
      final service = AppService();
      final appDetailIdRaw = arguments['appDetailId'];
      final requestedName = (arguments['name'] as String? ?? '').trim();
      String appType = (arguments['type'] as String?) ?? 'app';
      int? detailId;
      Map<String, dynamic> paramsMap =
          (arguments['params'] as Map?)?.cast<String, dynamic>() ?? {};

      if (appDetailIdRaw != null) {
        detailId = _toInt(appDetailIdRaw);
      } else {
        final appKey = (arguments['appKey'] as String? ?? '').trim();
        if (appKey.isEmpty) {
          return {'success': false, 'error': 'appKey is required'};
        }
        final app = await service.getAppByKey(appKey);
        if ((app.key ?? '').isEmpty || app.id == null) {
          return {'success': false, 'error': 'app not found: $appKey'};
        }
        final requestedVersion = (arguments['version'] as String? ?? '').trim();
        final versions = app.versions ?? const <String>[];
        final version = requestedVersion.isNotEmpty
            ? requestedVersion
            : (versions.isNotEmpty ? versions.first : '');
        if (version.isEmpty) {
          return {'success': false, 'error': 'no versions available: $appKey'};
        }

        // 与 MDUI3 安装对话框同链路：getAppDetail 返回的 id 即 appDetailId，
        // params 取表单字段默认值；无表单字段时不传 params 直接安装。
        final detail = await service.getAppDetail(
          '${app.id}',
          version,
          app.type ?? 'app',
        );
        if (detail.id == null) {
          return {'success': false, 'error': 'app detail not found: $appKey'};
        }
        detailId = detail.id;
        appType = app.type ?? 'app';
        for (final field in detail.params?.formFields ?? const <AppFormField>[]) {
          paramsMap[field.envKey] = field.defaultValue?.toString() ?? '';
        }
        if (requestedName.isNotEmpty) {
          arguments = <String, dynamic>{...arguments, 'name': requestedName};
        }
      }
      if (detailId == null) {
        return {'success': false, 'error': 'app detail not found'};
      }

      final cpuQuotaRaw = arguments['cpuQuota'];
      final memoryLimitRaw = arguments['memoryLimit'];
      final info = await service.installApp(AppInstallCreateRequest(
        appDetailId: detailId,
        name: requestedName.isNotEmpty ? requestedName : 'app',
        type: appType,
        advanced: arguments['advanced'] as bool? ?? false,
        containerName: arguments['containerName'] as String?,
        cpuQuota:
            cpuQuotaRaw == null ? null : double.tryParse(cpuQuotaRaw.toString()),
        memoryLimit: memoryLimitRaw == null
            ? null
            : double.tryParse(memoryLimitRaw.toString()),
        memoryUnit: (arguments['memoryUnit'] as String?) ?? 'MB',
        services: (arguments['services'] as Map?)?.cast<String, String>(),
        // 服务端对 params/taskID 为 null 时 POST /apps/install 返回 500
        // （2026-09-08 生产面板实测）：params 必须是空对象而非 null，
        // taskID 必须是唯一时间戳字符串（上游前端同语义）。
        params: paramsMap,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        hostMode: false,
        allowPort: true,
      ));
      return {'success': true, 'appId': info.id ?? 0};
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

  // ── 文件深度（B2）───────────────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b2_files_channel_contract.md。
  // 写语义：成功 `{success: true}`，失败 `{success: false, error}`；
  // 必填参数缺失时快速失败，不发出请求。

  /// 从设备选择文件并上传到服务器目录。参数：`{dir: String 目标目录必填}`
  static Future<Map<String, dynamic>> uploadFilesFromDevice(
      dynamic arguments) async {
    try {
      final dir = (arguments['dir'] as String? ?? '').trim();
      if (dir.isEmpty) {
        return {'success': false, 'error': 'dir is required'};
      }
      final paths = await PlatformFileService().pickFiles();
      if (paths.isEmpty) {
        return {'success': false, 'cancelled': true};
      }
      final service = FileBrowserService();
      for (final localPath in paths) {
        await service.uploadLocalFile(dir: dir, localPath: localPath);
      }
      return {'success': true, 'count': paths.length};
    } catch (e) {
      appLogger.e('uploadFilesFromDevice failed: $e');
      return _err(e);
    }
  }

  /// 下载服务器文件到设备。参数：`{path: String 文件全路径必填}`
  static Future<Map<String, dynamic>> downloadFileToDevice(
      dynamic arguments) async {
    try {
      final path = (arguments['path'] as String? ?? '').trim();
      if (path.isEmpty) {
        return {'success': false, 'error': 'path is required'};
      }
      final bytes = await FileBrowserService().downloadFile(path);
      if (bytes.isEmpty) {
        return {'success': false, 'error': 'empty file content'};
      }
      final fileName = path.split('/').last;
      final outcome = await PlatformFileService().saveBytesStructured(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: lookupMimeType(fileName),
      );
      if (outcome.isCancelled) {
        return {'success': false, 'cancelled': true};
      }
      return {
        'success': true,
        'uri': outcome.uri,
        'fileName': outcome.displayName,
        'privateFallbackUsed': outcome.privateFallbackUsed,
      };
    } catch (e) {
      appLogger.e('downloadFileToDevice failed: $e');
      return _err(e);
    }
  }

  /// 创建空文件（isDir=false 固定）。参数：`{path: String 全路径必填}`。
  /// POST /files。
  static Future<Map<String, dynamic>> createFileHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      if (path.isEmpty) {
        return {'success': false, 'error': 'path is required'};
      }
      await FileBrowserService().createFile(path);
      return _ok();
    } catch (e) {
      appLogger.e('createFileHandler failed: $e');
      return _err(e);
    }
  }

  /// 重命名文件/目录。参数：
  /// `{oldName: String 完整旧路径必填, newName: String 完整新路径必填}`。
  /// POST /files/rename。
  static Future<Map<String, dynamic>> renameFileHandler(
      dynamic arguments) async {
    try {
      final oldName = arguments['oldName'] as String? ?? '';
      final newName = arguments['newName'] as String? ?? '';
      if (oldName.isEmpty || newName.isEmpty) {
        return {'success': false, 'error': 'oldName and newName are required'};
      }
      await FileBrowserService().renameFile(oldName, newName);
      return _ok();
    } catch (e) {
      appLogger.e('renameFileHandler failed: $e');
      return _err(e);
    }
  }

  /// 移动/复制文件。参数：
  /// `{oldPaths: [String] 必填, newPath: String 目标目录必填,
  ///   type?: 'copy'|'cut'（缺省由 FileMove 默认 'cut'）}`。
  /// POST /files/move。
  static Future<Map<String, dynamic>> moveFilesHandler(
      dynamic arguments) async {
    try {
      final rawPaths = arguments['oldPaths'];
      final oldPaths =
          rawPaths is List ? rawPaths.map((e) => '$e').toList() : <String>[];
      final newPath = arguments['newPath'] as String? ?? '';
      if (oldPaths.isEmpty || newPath.isEmpty) {
        return {'success': false, 'error': 'oldPaths and newPath are required'};
      }
      await (await _fileApi()).moveFiles(FileMove(
        paths: oldPaths,
        targetPath: newPath,
        type: arguments['type'] as String?,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('moveFilesHandler failed: $e');
      return _err(e);
    }
  }

  /// 压缩文件。参数：
  /// `{files: [String] 必填, type: String(zip|gz|tar.gz…) 必填,
  ///   dst: String 必填, name: String 必填}`。POST /files/compress。
  static Future<Map<String, dynamic>> compressFilesHandler(
      dynamic arguments) async {
    try {
      final rawFiles = arguments['files'];
      final files =
          rawFiles is List ? rawFiles.map((e) => '$e').toList() : <String>[];
      final dst = arguments['dst'] as String? ?? '';
      final name = arguments['name'] as String? ?? '';
      final type = arguments['type'] as String? ?? '';
      if (files.isEmpty) {
        return {'success': false, 'error': 'files is required'};
      }
      if (dst.isEmpty || name.isEmpty || type.isEmpty) {
        return {'success': false, 'error': 'dst, name and type are required'};
      }
      await FileBrowserService().compressFiles(
        files: files,
        dst: dst,
        name: name,
        type: type,
      );
      return _ok();
    } catch (e) {
      appLogger.e('compressFilesHandler failed: $e');
      return _err(e);
    }
  }

  /// 解压文件。参数：
  /// `{path: String 必填, dst: String 必填, type: String 必填}`。
  /// POST /files/decompress。
  static Future<Map<String, dynamic>> decompressFileHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      final dst = arguments['dst'] as String? ?? '';
      final type = arguments['type'] as String? ?? '';
      if (path.isEmpty || dst.isEmpty || type.isEmpty) {
        return {'success': false, 'error': 'path, dst and type are required'};
      }
      await FileBrowserService().extractFile(path: path, dst: dst, type: type);
      return _ok();
    } catch (e) {
      appLogger.e('decompressFileHandler failed: $e');
      return _err(e);
    }
  }

  /// 修改文件权限。参数：
  /// `{path: String 必填, mode: int 必填（八进制值的十进制表达，493=0755）}`。
  /// POST /files/mode。mode 为服务端 os.FileMode 的十进制整型，原样透传。
  static Future<Map<String, dynamic>> changeFileModeHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      final mode = int.tryParse('${arguments['mode'] ?? ''}');
      if (path.isEmpty || mode == null) {
        return {'success': false, 'error': 'path and mode are required'};
      }
      await FileBrowserService().changeFileMode(path, mode);
      return _ok();
    } catch (e) {
      appLogger.e('changeFileModeHandler failed: $e');
      return _err(e);
    }
  }

  /// 修改文件所有者。参数：
  /// `{path: String 必填, user: String 必填, group: String 必填}`。
  /// POST /files/owner。
  static Future<Map<String, dynamic>> changeFileOwnerHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      final user = arguments['user'] as String? ?? '';
      final group = arguments['group'] as String? ?? '';
      if (path.isEmpty || user.isEmpty || group.isEmpty) {
        return {'success': false, 'error': 'path, user and group are required'};
      }
      await FileBrowserService().changeFileOwner(path, user, group);
      return _ok();
    } catch (e) {
      appLogger.e('changeFileOwnerHandler failed: $e');
      return _err(e);
    }
  }

  /// 保存文件内容。参数：
  /// `{path: String 必填, content: String 必填（可为空串，用于清空文件）}`。
  /// POST /files/save。
  static Future<Map<String, dynamic>> saveFileContentHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      final content = arguments['content'] as String?;
      if (path.isEmpty || content == null) {
        return {'success': false, 'error': 'path and content are required'};
      }
      await FileBrowserService().updateFileContent(path, content);
      return _ok();
    } catch (e) {
      appLogger.e('saveFileContentHandler failed: $e');
      return _err(e);
    }
  }

  /// 收藏文件/目录。参数：`{path: String 必填}`。POST /files/favorite。
  static Future<Map<String, dynamic>> addFavoriteHandler(
      dynamic arguments) async {
    try {
      final path = arguments['path'] as String? ?? '';
      if (path.isEmpty) {
        return {'success': false, 'error': 'path is required'};
      }
      await FileBrowserService().favoriteFile(path);
      return _ok();
    } catch (e) {
      appLogger.e('addFavoriteHandler failed: $e');
      return _err(e);
    }
  }

  /// 取消收藏。参数：`{id: int 必填}`。POST /files/favorite/del。
  /// 契约偏差：FileUnfavorite 模型仅含 path，而 Swagger
  /// request.FavoriteDelete 必填 id（上游前端同语义 `{id}`），
  /// 故按原始键直发，file_v2.dart 不改动。
  static Future<Map<String, dynamic>> removeFavoriteHandler(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/files/favorite/del'),
        data: {'id': id},
      );
      return _ok();
    } catch (e) {
      appLogger.e('removeFavoriteHandler failed: $e');
      return _err(e);
    }
  }

  /// Wget 远程下载。参数：
  /// `{url: String 必填, path: String 目标目录必填, name: String 保存名必填}`。
  /// POST /files/wget。
  static Future<Map<String, dynamic>> wgetDownloadHandler(
      dynamic arguments) async {
    try {
      final url = arguments['url'] as String? ?? '';
      final path = arguments['path'] as String? ?? '';
      final name = arguments['name'] as String? ?? '';
      if (url.isEmpty || path.isEmpty || name.isEmpty) {
        return {'success': false, 'error': 'url, path and name are required'};
      }
      await (await _fileApi())
          .wgetDownload(FileWgetRequest(url: url, path: path, name: name));
      return _ok();
    } catch (e) {
      appLogger.e('wgetDownloadHandler failed: $e');
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

  /// 恢复备份记录。参数（字段与 getBackups 行一致，整行回传）：
  /// `{id: int, name: String, type: String, detailName?: String,
  ///   fileName: String, fileDir?: String, downloadAccountID?: int}`
  static Future<Map<String, dynamic>> restoreBackup(dynamic arguments) async {
    try {
      final fileName = (arguments['fileName'] as String? ?? '').trim();
      final type = arguments['type'] as String? ?? '';
      if (fileName.isEmpty || type.isEmpty) {
        return {'success': false, 'error': 'fileName and type are required'};
      }
      final fileDir = arguments['fileDir'] as String? ?? '';
      final recordId = int.tryParse('${arguments['id'] ?? ''}');
      await BackupRecoverService().recover(
        BackupRecoverRequest(
          downloadAccountID:
              int.tryParse('${arguments['downloadAccountID'] ?? 0}') ?? 0,
          type: type,
          name: arguments['name'] as String? ?? '',
          detailName: arguments['detailName'] as String? ?? '',
          file: fileDir.isEmpty ? fileName : '$fileDir/$fileName',
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
          backupRecordID: recordId,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('restoreBackup failed: $e');
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

  // ── 定时任务（建/改/执行一次） ───────────────────────────────────────────

  static CronjobOperateRequest _buildCronjobRequest(
    dynamic arguments, {
    int? id,
    Map<String, dynamic> existing = const <String, dynamic>{},
  }) =>
      buildCronjobOperateRequest(
        arguments as Map,
        id: id,
        existing: existing,
      );

  /// 新建 shell 定时任务。参数：
  /// `{name: String, spec: String(cron 表达式), script?: String, groupID?: int}`
  static Future<Map<String, dynamic>> createCronJob(dynamic arguments) async {
    try {
      final request = _buildCronjobRequest(arguments);
      await CronjobFormRepository().createCronjob(request);
      return _ok();
    } catch (e) {
      appLogger.e('createCronJob failed: $e');
      return _err(e);
    }
  }

  /// 编辑 shell 定时任务。参数：`{id: int} + 同 createCronJob`
  static Future<Map<String, dynamic>> updateCronJob(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final info = await ApiClientManager.instance
          .getCronjobApi()
          .then((api) => api.loadCronjobInfo(id));
      final existing = <String, dynamic>{
        'type': info.data?.type ?? '',
        'groupID': info.data?.groupID ?? 0,
        'executor': info.data?.executor ?? '',
        'scriptMode': info.data?.scriptMode ?? 'input',
        'command': info.data?.command ?? '',
        'containerName': info.data?.containerName ?? '',
        'user': info.data?.user ?? '',
        'scriptID': info.data?.scriptID ?? 0,
        'appID': info.data?.appID ?? '',
        'website': info.data?.website ?? '',
        'exclusionRules': info.data?.exclusionRules ?? '',
        'dbType': info.data?.dbType ?? '',
        'dbName': info.data?.dbName ?? '',
        'url': info.data?.url ?? '',
        'isDir': info.data?.isDir ?? false,
        'sourceDir': info.data?.sourceDir ?? '',
        'snapshotRule': info.data?.snapshotRule.toJson() ?? const {},
        'sourceAccountIDs': info.data?.sourceAccountIDs ?? '',
        'downloadAccountID': info.data?.downloadAccountID ?? 0,
        'retainCopies': info.data?.retainCopies ?? 1,
        'retryTimes': info.data?.retryTimes ?? 0,
        'timeout': info.data?.timeout ?? 3600,
        'ignoreErr': info.data?.ignoreErr ?? false,
        'secret': info.data?.secret ?? '',
        'args': info.data?.args ?? '',
        'alertCount': info.data?.alertCount ?? 0,
        'alertTitle': info.data?.alertTitle ?? '',
        'alertMethod': info.data?.alertMethod ?? '',
        'scopes': info.data?.scopes ?? const <String>[],
      };
      final request = _buildCronjobRequest(arguments, id: id, existing: existing);
      await CronjobFormRepository().updateCronjob(request);
      return _ok();
    } catch (e) {
      appLogger.e('updateCronJob failed: $e');
      return _err(e);
    }
  }

  /// 立即执行一次。参数：`{id: int}`
  static Future<Map<String, dynamic>> handleCronJobOnce(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await CronjobRepository().handleOnce(id);
      return _ok();
    } catch (e) {
      appLogger.e('handleCronJobOnce failed: $e');
      return _err(e);
    }
  }

  // ── AI 模型生命周期（B14 扩展；域名绑定需 appInstallID 发现流，后续批次） ──

  /// 创建（拉取）Ollama 模型。参数：`{name: String}`
  static Future<Map<String, dynamic>> createAIModel(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await AIRepository().createOllamaModel(
        name: name,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createAIModel failed: $e');
      return _err(e);
    }
  }

  /// 重建 Ollama 模型。参数：`{name: String}`
  static Future<Map<String, dynamic>> recreateAIModel(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await AIRepository().recreateOllamaModel(
        name: name,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      return _ok();
    } catch (e) {
      appLogger.e('recreateAIModel failed: $e');
      return _err(e);
    }
  }

  // ── 主机 SSH（B15）──────────────────────────────────────────────────────

  static const Set<String> _sshOperations = {'start', 'stop', 'restart'};

  /// SSH 服务操作。参数：`{operation: 'start'|'stop'|'restart'}`
  static Future<Map<String, dynamic>> operateSsh(dynamic arguments) async {
    try {
      final operation = arguments['operation'] as String? ?? '';
      if (!_sshOperations.contains(operation)) {
        return {'success': false, 'error': 'Unsupported operation: $operation'};
      }
      await SSHService().operate(operation);
      return _ok();
    } catch (e) {
      appLogger.e('operateSsh failed: $e');
      return _err(e);
    }
  }

  /// 保存 SSH 原始配置。参数：`{value: String}`
  static Future<Map<String, dynamic>> saveSshConfig(dynamic arguments) async {
    try {
      final value = arguments['value'] as String? ?? '';
      if (value.trim().isEmpty) {
        return {'success': false, 'error': 'config value is required'};
      }
      await SSHService().saveRawConfig(value);
      return _ok();
    } catch (e) {
      appLogger.e('saveSshConfig failed: $e');
      return _err(e);
    }
  }

  // ── 工具箱（B15）────────────────────────────────────────────────────────

  /// DNS 连通性校验（非破坏）。参数：`{dns: String}`
  static Future<Map<String, dynamic>> verifyToolboxDns(dynamic arguments) async {
    try {
      final dns = (arguments['dns'] as String? ?? '').trim();
      if (dns.isEmpty) {
        return {'success': false, 'error': 'dns is required'};
      }
      // 上游契约：key='form'（表单形态），value 为逗号分隔 DNS 列表。
      await ToolboxDeviceService().verifyDns('form', dns);
      return _ok();
    } catch (e) {
      appLogger.e('verifyToolboxDns failed: $e');
      return _err(e);
    }
  }

  // ── OpenResty（B16）─────────────────────────────────────────────────────

  /// 保存 OpenResty 配置源文本。参数：`{content: String 非空}`
  static Future<Map<String, dynamic>> updateOpenrestyConfig(
      dynamic arguments) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.trim().isEmpty) {
        return {'success': false, 'error': 'content is required'};
      }
      await OpenRestyService().updateConfigSource(content);
      return _ok();
    } catch (e) {
      appLogger.e('updateOpenrestyConfig failed: $e');
      return _err(e);
    }
  }

  // ── 命令库（B17）────────────────────────────────────────────────────────

  /// 命令库列表。参数：`{type?: String 默认 'command'}`
  static Future<dynamic> getCommands(dynamic arguments) async {
    try {
      final type = arguments?['type'] as String? ?? 'command';
      final commands = await CommandService().listCommands(type: type);
      return commands
          .map((c) => {
                'id': c.id ?? 0,
                'name': c.name ?? '',
                'command': c.command ?? '',
                'groupID': c.groupID ?? 0,
                'groupBelong': c.groupBelong ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get commands for native: $e');
      return [];
    }
  }

  /// 新建命令。参数：`{name: String 必填, command: String 必填, groupID?: int}`
  static Future<Map<String, dynamic>> createCommand(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final command = (arguments['command'] as String? ?? '').trim();
      if (name.isEmpty || command.isEmpty) {
        return {'success': false, 'error': 'name and command are required'};
      }
      await CommandService().createCommand(
        CommandOperate(
          name: name,
          command: command,
          groupID: int.tryParse('${arguments['groupID'] ?? 0}') ?? 0,
          type: 'command',
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createCommand failed: $e');
      return _err(e);
    }
  }

  /// 删除命令。参数：`{id: int}`
  static Future<Map<String, dynamic>> deleteCommand(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await CommandService().deleteCommands([id]);
      return _ok();
    } catch (e) {
      appLogger.e('deleteCommand failed: $e');
      return _err(e);
    }
  }

  /// 分组列表（命令库下拉数据源）。参数：`{type: String 默认 'command'}`
  static Future<dynamic> getGroups(dynamic arguments) async {
    try {
      final type = arguments?['type'] as String? ?? 'command';
      final groups = await GroupService().listGroups(type);
      return groups
          .map((g) => {'id': g.id, 'name': g.name})
          .toList();
    } catch (e) {
      appLogger.e('Failed to get groups for native: $e');
      return [];
    }
  }

  // ── AI 发现流（B17，域名绑定前置）───────────────────────────────────────

  /// 发现 Ollama 安装实例（appInstallID 供域名绑定使用）。
  /// 返回：`{found: bool, appInstallId?: int, name?, status?, candidates?: [int]}`
  static Future<dynamic> getOllamaContext(dynamic arguments) async {
    try {
      final apps = await AppService().getInstalledApps();
      final hits = apps
          .where((a) => (a.appKey ?? '') == 'ollama')
          .toList()
        ..sort((x, y) {
          final xr = x.status == 'Running' ? 0 : 1;
          final yr = y.status == 'Running' ? 0 : 1;
          if (xr != yr) return xr - yr;
          return (x.id ?? 0).compareTo(y.id ?? 0);
        });
      if (hits.isEmpty) {
        return {'found': false};
      }
      final first = hits.first;
      return {
        'found': true,
        'appInstallId': first.id ?? 0,
        'name': first.name,
        'status': first.status,
        'candidates': hits.map((x) => x.id ?? 0).toList(),
      };
    } catch (e) {
      appLogger.e('getOllamaContext failed: $e');
      return {'found': false};
    }
  }

  // ── AI 域名绑定（B17，消费 getOllamaContext 发现流）─────────────────────

  /// 绑定 AI 服务域名。参数：
  /// `{appInstallID: int(>0，来自 getOllamaContext), domain: String 必填,
  ///   ipList?: String 逗号分隔原样传}`
  static Future<Map<String, dynamic>> bindAIDomain(dynamic arguments) async {
    try {
      final appInstallID = int.tryParse('${arguments['appInstallID'] ?? 0}') ?? 0;
      final domain = (arguments['domain'] as String? ?? '').trim();
      if (appInstallID <= 0) {
        return {'success': false, 'error': 'appInstallID is required'};
      }
      if (domain.isEmpty) {
        return {'success': false, 'error': 'domain is required'};
      }
      final ipList = (arguments['ipList'] as String? ?? '').trim();
      await AIRepository().bindDomain(
        appInstallID: appInstallID,
        domain: domain,
        ipList: ipList.isEmpty ? null : ipList,
      );
      return _ok();
    } catch (e) {
      appLogger.e('bindAIDomain failed: $e');
      return _err(e);
    }
  }

  // ── 编排 Compose（B18，操作最小集）──────────────────────────────────────

  static const Set<String> _composeActions = {
    'up', 'down', 'start', 'stop', 'restart', 'delete', 'rebuild',
  };

  /// Compose 项目操作。参数：
  /// `{name: String 必填, operation: up|start|restart|stop|down|delete|rebuild 必填,
  ///   path?: String}`
  /// 服务端 ComposeOperation 契约（2026-09-08 swagger 实证）：以 name +
  /// operation 定位，无 id 字段；字段名为 operation 而非 action。
  static Future<Map<String, dynamic>> composeOperate(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final operation = (arguments['operation'] ?? arguments['action'] ?? '')
          .toString()
          .trim();
      final path = (arguments['path'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      if (!_composeActions.contains(operation)) {
        return {'success': false, 'error': 'Unsupported operation: $operation'};
      }
      final compose = ContainerCompose(
        id: '',
        name: name,
        path: path.isEmpty ? null : path,
      );
      final service = OrchestrationService();
      switch (operation) {
        case 'up':
          await service.upCompose(compose);
        case 'down':
          await service.downCompose(compose);
        case 'start':
          await service.startCompose(compose);
        case 'stop':
          await service.stopCompose(compose);
        case 'restart':
          await service.restartCompose(compose);
        case 'delete':
          await service.deleteCompose(
            compose,
            force: arguments['force'] == true,
            withFile: arguments['withFile'] == true,
          );
      }
      return _ok();
    } catch (e) {
      appLogger.e('composeOperate failed: $e');
      return _err(e);
    }
  }

  // ── 安全网关（B18，只读最小集）──────────────────────────────────────────

  /// 面板 SSL 信息。
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

  /// 网站证书列表（核心字段）。
  static Future<dynamic> getWebsiteCertificates(dynamic arguments) async {
    try {
      final certs = await WebsiteCertificateService().searchCertificates(
        pageSize: 50,
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

  // ── Compose 建/改（B19）──────────────────────────────────────────────────

  /// 新建 Compose。参数：
  /// `{name: String 必填, from?: 'path'|'raw'|'edit' 默认 'path', path?: String(from=path 必填), file?: String(内容)}`
  /// 服务端 ComposeCreate.from 枚举为 edit|path|template（无 raw，上游 400
  /// oneof 校验实测），'raw' 在此归一化为 'edit'。
  static Future<Map<String, dynamic>> createCompose(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      var from = arguments['from'] as String? ?? 'path';
      if (from == 'raw') {
        from = 'edit';
      }
      final path = (arguments['path'] as String? ?? '').trim();
      if (from == 'path' && path.isEmpty) {
        return {'success': false, 'error': 'path is required when from=path'};
      }
      if (from == 'template' &&
          int.tryParse('${arguments['template'] ?? ''}') == null) {
        return {'success': false, 'error': 'template is required when from=template'};
      }
      await OrchestrationService().createCompose(
        ContainerComposeCreate(
          from: from,
          name: name,
          path: path.isEmpty ? null : path,
          file: arguments['file'] as String?,
          template: int.tryParse('${arguments['template'] ?? ''}'),
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createCompose failed: $e');
      return _err(e);
    }
  }

  /// 编辑 Compose 配置。参数：
  /// `{name: String 必填, path: String 必填, content: String 必填, detailPath?: String}`
  static Future<Map<String, dynamic>> updateCompose(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final path = (arguments['path'] as String? ?? '').trim();
      final content = arguments['content'] as String? ?? '';
      final detailPath = (arguments['detailPath'] as String? ?? '').trim();
      if (name.isEmpty || path.isEmpty || content.trim().isEmpty) {
        return {'success': false, 'error': 'name, path and content are required'};
      }
      await OrchestrationService().updateCompose(
        ContainerComposeUpdateRequest(
          name: name,
          path: path,
          content: content,
          detailPath: detailPath.isEmpty ? null : detailPath,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateCompose failed: $e');
      return _err(e);
    }
  }

  /// 校验 Compose 配置。参数：`{name: String 必填, content: String 必填}`
  static Future<Map<String, dynamic>> testCompose(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final content = arguments['content'] as String? ?? '';
      if (name.isEmpty || content.trim().isEmpty) {
        return {'success': false, 'error': 'name and content are required'};
      }
      await OrchestrationService().testCompose(
        ContainerComposeCreate(
          from: 'edit',
          name: name,
          file: content,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('testCompose failed: $e');
      return _err(e);
    }
  }

  /// 清理 Compose 日志。参数：`{name: String 必填, path: String 必填}`
  static Future<Map<String, dynamic>> cleanComposeLog(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final path = (arguments['path'] as String? ?? '').trim();
      if (name.isEmpty || path.isEmpty) {
        return {'success': false, 'error': 'name and path are required'};
      }
      await OrchestrationService().cleanComposeLog(
        ContainerComposeLogCleanRequest(name: name, path: path),
      );
      return _ok();
    } catch (e) {
      appLogger.e('cleanComposeLog failed: $e');
      return _err(e);
    }
  }

  // ── 网关 HTTPS 开关（B19）────────────────────────────────────────────────

  static const Set<String> _httpsOperates = {'enable', 'disable'};

  /// OpenResty 默认 HTTPS 跳转开关。参数：
  /// `{operate: 'enable'|'disable', sslRejectHandshake?: bool}`
  static Future<Map<String, dynamic>> updateOpenrestyHttps(
      dynamic arguments) async {
    try {
      final operate = (arguments['operate'] as String? ?? '').trim();
      if (!_httpsOperates.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operate: $operate'};
      }
      await OpenRestyService().updateHttps({
        'operate': operate,
        if (arguments['sslRejectHandshake'] != null)
          'sslRejectHandshake': arguments['sslRejectHandshake'],
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateOpenrestyHttps failed: $e');
      return _err(e);
    }
  }

  // ── 脚本库（B20）────────────────────────────────────────────────────────

  /// 批量删除脚本。参数：`{ids: [int,...]}`（单选/多选均可）
  static Future<Map<String, dynamic>> deleteScripts(dynamic arguments) async {
    try {
      final raw = arguments['ids'];
      final ids = <int>[];
      if (raw is List) {
        for (final v in raw) {
          final id = int.tryParse('$v');
          if (id != null) {
            ids.add(id);
          }
        }
      }
      if (ids.isEmpty) {
        return {'success': false, 'error': 'ids is required'};
      }
      await ScriptLibraryService().deleteScripts(ids);
      return _ok();
    } catch (e) {
      appLogger.e('deleteScripts failed: $e');
      return _err(e);
    }
  }

  // ── 证书上传（B21，网关写策略）──────────────────────────────────────────

  /// 上传证书（粘贴形态）。参数：
  /// `{certificate: String 必填, privateKey: String 必填, description?: String}`
  static Future<Map<String, dynamic>> uploadCertificate(
      dynamic arguments) async {
    try {
      final certificate = (arguments['certificate'] as String? ?? '').trim();
      final privateKey = (arguments['privateKey'] as String? ?? '').trim();
      if (certificate.isEmpty || privateKey.isEmpty) {
        return {'success': false, 'error': 'certificate and privateKey are required'};
      }
      final description = (arguments['description'] as String? ?? '').trim();
      await WebsiteCertificateService().uploadCertificate(
        WebsiteSSLUpload(
          type: 'paste',
          certificate: certificate,
          privateKey: privateKey,
          description: description.isEmpty ? null : description,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('uploadCertificate failed: $e');
      return _err(e);
    }
  }

  /// 应用（申请/续签）证书。参数：`{id: int 必填}`
  static Future<Map<String, dynamic>> applyCertificate(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await WebsiteCertificateService().applyCertificate(
        WebsiteSSLApply(id: id),
      );
      return _ok();
    } catch (e) {
      appLogger.e('applyCertificate failed: $e');
      return _err(e);
    }
  }

  /// 删除证书。参数：`{id: int 必填}`
  static Future<Map<String, dynamic>> deleteWebsiteCertificate(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await WebsiteCertificateService().deleteCertificate(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteWebsiteCertificate failed: $e');
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

  /// 下载备份记录到设备。参数：
  /// `{downloadAccountID?: int, fileDir: String, fileName: String}`
  static Future<Map<String, dynamic>> downloadBackupRecord(
      dynamic arguments) async {
    try {
      final fileName = (arguments['fileName'] as String? ?? '').trim();
      if (fileName.isEmpty) {
        return {'success': false, 'error': 'fileName is required'};
      }
      final record = BackupRecord(
        downloadAccountID: _toInt(arguments['downloadAccountID']),
        fileDir: arguments['fileDir'] as String? ?? '',
        fileName: fileName,
        status: '',
      );
      final result = await BackupRecordService().downloadRecord(record);
      if (result.wasCancelled) {
        return {'success': false, 'cancelled': true};
      }
      if (!result.success) {
        return {
          'success': false,
          'error': result.errorMessage ?? 'download failed',
        };
      }
      return {
        'success': true,
        'filePath': result.filePath ?? '',
        'fileName': result.displayName ?? fileName,
        'privateFallbackUsed': result.privateFallbackUsed,
      };
    } catch (e) {
      appLogger.e('downloadBackupRecord failed: $e');
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
      final port = (arguments['port'] as String? ?? '').trim();
      final protocol = arguments['protocol'] as String? ?? 'tcp';
      final address = (arguments['address'] as String? ?? '').trim();
      final strategy = arguments['strategy'] as String? ?? 'accept';
      final description = (arguments['description'] as String? ?? '').trim();
      final service = FirewallService();
      if (port.isNotEmpty) {
        await service.createPortRule(FirewallPortRulePayload(
          operation: 'add',
          address: address,
          port: port,
          source: address.isEmpty ? 'anyWhere' : 'address',
          protocol: protocol,
          strategy: strategy,
          description: description.isEmpty ? null : description,
        ));
      } else if (address.isNotEmpty) {
        await service.createIpRule(FirewallIpRulePayload(
          operation: 'add',
          address: address,
          strategy: strategy,
          description: description.isEmpty ? null : description,
        ));
      } else {
        throw const FormatException('Enter a port or source address.');
      }
      return _ok();
    } catch (e) {
      appLogger.e('addFirewallRule failed: $e');
      return _err(e);
    }
  }

  /// 使用列表标识或旧版规则字段删除防火墙规则。
  static Future<Map<String, dynamic>> deleteFirewallRule(
      dynamic arguments) async {
    try {
      final service = FirewallService();
      final serverId = arguments['serverId'] as String?;
      if (arguments.containsKey('inventoryId')) {
        final id = arguments['inventoryId'] as String?;
        if (id == null || id.isEmpty || serverId == null || serverId.isEmpty) {
          throw const FormatException('Invalid firewall inventory identity.');
        }
        await service.deleteInventoryRulesById([id], serverId: serverId);
        return _ok();
      }
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
      await service.deleteRules(request, expectedServerId: serverId);
      return _ok();
    } catch (e) {
      appLogger.e('deleteFirewallRule failed: $e');
      return _err(e);
    }
  }

  // ── 缓存 ──────────────────────────────────────────────────────────────────

  /// 清除文件预览的内存和磁盘缓存。无参数。
  static Future<Map<String, dynamic>> clearCache(dynamic arguments) async {
    try {
      await FilePreviewCacheManager().clearAllCache();
      return _ok();
    } catch (e) {
      appLogger.e('clearCache failed: $e');
      return _err(e);
    }
  }

  // ── 设置 ────────────────────────────────────────────────────────────────

  /// 写客户端偏好（供 WinUI3 原生宿主切换渲染模式/语言）。
  /// 参数：`{key: 'renderMode'|'language', value: String}`
  static Future<Map<String, dynamic>> updateSetting(dynamic arguments) async {
    try {
      final key = arguments['key'] as String;
      final value = arguments['value'] as String?;
      final prefs = AppPreferencesService();
      switch (key) {
        case 'renderMode':
          final mode = UIRenderMode.values.asNameMap()[value];
          if (mode == null) throw ArgumentError.value(value, key);
          await prefs.saveUIRenderMode(mode);
          return _ok();
        case 'language':
          final locale =
              value == null || value == 'system' ? null : Locale(value);
          if (locale != null &&
              !AppLocalizations.supportedLocales.contains(locale)) {
            throw ArgumentError.value(value, key);
          }
          await prefs.saveLocale(locale);
          return _ok();
        default:
          return {'success': false, 'error': 'Unknown setting key: $key'};
      }
    } catch (e) {
      appLogger.e('updateSetting failed: $e');
      return _err(e);
    }
  }

  /// OpenResty 未安装判定（/websites/check preCheck 返回项）。
  /// 上游建站向导语义：未安装时拦截创建并提示先装 OpenResty，
  /// 而不是提交一个注定以 "record not found" 失败的创建。
  static bool openrestyMissingInPreCheck(List<Map<String, dynamic>> checks) =>
      checks.any(
        (item) =>
            '${item['appName'] ?? ''}'.toLowerCase().contains('openresty') &&
            '${item['status'] ?? ''}'.contains('未安装'),
      );

  /// 新建网站（WinUI3 网站页新建表单，最小字段集对齐 Flutter 建站向导
  /// 的 deployment 缺省路径）。参数：
  /// `{primaryDomain: String, alias?: String, port?: int|String(default 80),
  ///   type?: String(default 'deployment'), remark?: String}`
  static Future<Map<String, dynamic>> createWebsite(dynamic arguments) async {
    try {
      final primaryDomain =
          (arguments['primaryDomain'] as String? ?? '').trim();
      if (primaryDomain.isEmpty) {
        return {'success': false, 'error': 'primaryDomain is required'};
      }
      final alias =
          (arguments['alias'] as String? ?? '').trim().isNotEmpty
              ? (arguments['alias'] as String).trim()
              : primaryDomain.replaceAll('.', '_');
      final port = int.tryParse('${arguments['port'] ?? 80}') ?? 80;
      final type = arguments['type'] as String? ?? 'deployment';
      final remark = (arguments['remark'] as String? ?? '').trim();

      // 服务端要求 webSiteGroupId 必填且必须存在（record not found 兜底）：
      // 新装面板无 website 分组时先创建默认分组。
      var groups = await GroupService().listGroups('website');
      if (groups.isEmpty) {
        groups = await GroupService().createGroup(
          type: 'website',
          name: '默认网站',
        );
      }
      final groupId = groups.first.id ?? 1;

      // 与 Flutter 建站向导同序：先 preCheck 再 create；OpenResty 未安装时
      // 快速失败，不提交注定失败的创建。
      final checks = await WebsiteRepository().preCheckWebsite({});
      if (openrestyMissingInPreCheck(checks)) {
        return {
          'success': false,
          'error': 'OpenResty 未安装，请先在 1Panel 应用商店安装 OpenResty 后再创建网站',
        };
      }
      // 服务端按 appInstallID 定位 openresty 安装实例（record not found 实测根因）。
      int? openrestyInstallId;
      try {
        final installed = await AppService().getInstalledApps();
        for (final a in installed) {
          if ((a.appKey ?? '').toLowerCase() == 'openresty' &&
              a.id != null &&
              a.id! > 0) {
            openrestyInstallId = a.id;
            break;
          }
        }
      } catch (e) {
        appLogger.w('createWebsite: discover openresty install failed: $e');
      }
      await WebsiteRepository().createWebsite(
        WebsiteCreate(
          alias: alias,
          name: primaryDomain,
          remark: remark.isEmpty ? null : remark,
          type: type,
          // 服务端要求 appType 枚举（new/installed）：静态部署挂已装 OpenResty
          appType: type == 'deployment' ? 'installed' : null,
          appInstallId: openrestyInstallId,
          webSiteGroupId: groupId,
          port: port,
          domains: [
            WebsiteDomain(domain: primaryDomain, port: port, ssl: false),
          ],
          taskId: DateTime.now().millisecondsSinceEpoch.toString(),
          ipv6: false,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createWebsite failed: $e');
      return _err(e);
    }
  }

  // ── 数据库 ────────────────────────────────────────────────────────────────

  /// 新建数据库（本地部署最小集；remote 需连接信息）。
  /// 参数：`{name: String, type?: String(scope, 默认 mysql), description?: String,
  ///        address?: String, port?: int|String, username?: String, password?: String}`
  static Future<Map<String, dynamic>> createDatabase(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      final type = arguments['type'] as String? ?? 'mysql';
      final scope = DatabaseScope.values.firstWhere(
        (s) => s.value == type,
        orElse: () => DatabaseScope.mysql,
      );
      final isRemote = scope == DatabaseScope.remote || type == 'remote';
      final port = int.tryParse('${arguments['port'] ?? ''}');
      // 服务端 MysqlDBCreate required：database（目标实例名）/format/permission
      // （2026-09-08 生产面板 400 实测），本地建库缺一不可。
      var createInput = DatabaseFormInput(
        scope: scope,
        name: name,
        engine: type,
        source: isRemote ? 'remote' : 'local',
        description: (arguments['description'] as String? ?? '').trim(),
        address: arguments['address'] as String?,
        port: port,
        username: arguments['username'] as String?,
        password: arguments['password'] as String?,
        targetDatabase: (arguments['database'] as String? ?? '').trim(),
        format: (arguments['format'] as String? ?? '').trim(),
        permission: (arguments['permission'] as String? ?? '').trim(),
      );
      if (!isRemote && (createInput.targetDatabase == null ||
              createInput.targetDatabase!.isEmpty)) {
        // 自动发现：取首个本地 MySQL 安装实例名（上游建库目标实例下拉语义）。
        try {
          final installed = await AppService().getInstalledApps();
          for (final a in installed) {
            if ((a.appKey ?? '').toLowerCase() == 'mysql' &&
                a.id != null &&
                a.id! > 0) {
              createInput = DatabaseFormInput(
                scope: createInput.scope,
                name: createInput.name,
                engine: createInput.engine,
                source: createInput.source,
                description: createInput.description,
                address: createInput.address,
                port: createInput.port,
                username: createInput.username,
                password: createInput.password,
                targetDatabase: a.name,
                // 重建时必须保留服务端 required 字段（B11 400 回归：
                // MysqlDBCreate.Format/Permission），否则注入实例名后
                // format/permission 静默丢失。
                format: createInput.format,
                permission: createInput.permission,
              );
              break;
            }
          }
        } catch (e) {
          appLogger.w('createDatabase: discover mysql install failed: $e');
        }
        if (createInput.targetDatabase == null ||
            createInput.targetDatabase!.isEmpty) {
          return {
            'success': false,
            'error':
                'database is required for local create (target MySQL instance name)',
          };
        }
      }
      await DatabasesService().submitForm(createInput);
      return _ok();
    } catch (e) {
      appLogger.e('createDatabase failed: $e');
      return _err(e);
    }
  }

  /// 删除数据库。参数：`{id: int|String}`
  static Future<Map<String, dynamic>> deleteDatabase(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await DatabasesService().deleteDatabase(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteDatabase failed: $e');
      return _err(e);
    }
  }

  /// 重建供改写操作使用的最小条目（字段覆盖 repository 各分支所需）。
  static DatabaseListItem _rebuildDatabaseItem(dynamic arguments) {
    final lookupName =
        (arguments['lookupName'] as String? ?? '').trim();
    final name = (arguments['name'] as String? ?? '').trim();
    if (lookupName.isEmpty && name.isEmpty) {
      throw ArgumentError('lookupName or name is required');
    }
    final type = arguments['scope'] as String? ?? 'mysql';
    return DatabaseListItem(
      scope: DatabaseScope.values.firstWhere(
        (s) => s.value == type,
        orElse: () => DatabaseScope.mysql,
      ),
      id: int.tryParse('${arguments['id'] ?? ''}'),
      name: name,
      engine: arguments['engine'] as String? ?? type,
      source: arguments['source'] as String? ?? 'local',
      database: lookupName.isEmpty ? null : lookupName,
    );
  }

  /// 修改数据库描述。参数：`{scope, lookupName?|name, engine?, source?, id?, description}`
  static Future<Map<String, dynamic>> updateDatabaseDescription(
      dynamic arguments) async {
    try {
      final description = arguments['description'] as String? ?? '';
      final item = _rebuildDatabaseItem(arguments);
      await DatabasesService().updateDescription(item, description);
      return _ok();
    } catch (e) {
      appLogger.e('updateDatabaseDescription failed: $e');
      return _err(e);
    }
  }

  /// 修改数据库密码。参数：`{scope, lookupName?|name, engine?, source?, id?, password}`
  static Future<Map<String, dynamic>> changeDatabasePassword(
      dynamic arguments) async {
    try {
      final password = arguments['password'] as String? ?? '';
      if (password.isEmpty) {
        return {'success': false, 'error': 'password is required'};
      }
      final item = _rebuildDatabaseItem(arguments);
      await DatabasesService().changePassword(item, password);
      return _ok();
    } catch (e) {
      appLogger.e('changeDatabasePassword failed: $e');
      return _err(e);
    }
  }

  // ── AI 管理深度（B3）────────────────────────────────────────────────────
  // 契约单一事实源：docs/development/modules/b3_ai_channel_contract.md。

  /// 创建智能体渠道账号。参数：
  /// `{provider, name, apiKey, baseURL, apiType 必填, authMode?,
  ///   validateAvailability?, verifyModel?, remark?}`。
  /// POST /ai/accounts。契约 authMode/validateAvailability/verifyModel 在
  /// AgentAccountCreateReq 无对应字段，按底层实际能力丢弃（ai_v2.dart 不改）。
  static Future<Map<String, dynamic>> createAgentAccountNative(
      dynamic arguments) async {
    try {
      final provider = (arguments['provider'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      final apiKey = (arguments['apiKey'] as String? ?? '').trim();
      final baseURL = (arguments['baseURL'] as String? ?? '').trim();
      final apiType = (arguments['apiType'] as String? ?? '').trim();
      if (provider.isEmpty || name.isEmpty || apiKey.isEmpty) {
        return {
          'success': false,
          'error': 'provider, name and apiKey are required',
        };
      }
      if (baseURL.isEmpty || apiType.isEmpty) {
        return {'success': false, 'error': 'baseURL and apiType are required'};
      }
      await (await AIRepository().getApi()).createAgentAccount(
        AgentAccountCreateReq(
          provider: provider,
          name: name,
          apiKey: apiKey,
          rememberApiKey: true,
          baseURL: baseURL,
          apiType: apiType,
          remark: arguments['remark'] as String? ?? '',
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createAgentAccountNative failed: $e');
      return _err(e);
    }
  }

  /// 更新智能体渠道账号。参数：
  /// `{id: int 必填, provider, name, apiKey, baseURL, apiType 必填, remark?}`。
  /// POST /ai/accounts/update。契约 provider 在 AgentAccountUpdateReq
  /// 无对应字段，按底层实际能力丢弃（ai_v2.dart 不改）。
  static Future<Map<String, dynamic>> updateAgentAccountNative(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final name = (arguments['name'] as String? ?? '').trim();
      final baseURL = (arguments['baseURL'] as String? ?? '').trim();
      final apiType = (arguments['apiType'] as String? ?? '').trim();
      if (name.isEmpty || baseURL.isEmpty || apiType.isEmpty) {
        return {
          'success': false,
          'error': 'name, baseURL and apiType are required',
        };
      }
      await (await AIRepository().getApi()).updateAgentAccount(
        AgentAccountUpdateReq(
          id: id,
          name: name,
          apiKey: arguments['apiKey'] as String? ?? '',
          rememberApiKey: true,
          baseURL: baseURL,
          apiType: apiType,
          remark: arguments['remark'] as String? ?? '',
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateAgentAccountNative failed: $e');
      return _err(e);
    }
  }

  /// 删除智能体渠道账号。参数：`{id: int}`。POST /ai/accounts/delete。
  static Future<Map<String, dynamic>> deleteAgentAccountNative(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await (await AIRepository().getApi())
          .deleteAgentAccount(AgentAccountDeleteReq(id: id));
      return _ok();
    } catch (e) {
      appLogger.e('deleteAgentAccountNative failed: $e');
      return _err(e);
    }
  }

  /// 从渠道供应商发现可用模型。参数：
  /// `{provider, baseURL, apiKey, apiType 必填}`。
  /// POST /ai/accounts/models/discover。按契约写通道惯例只回执
  /// 成功/失败（发现结果供服务端落库与后续 models 查询使用）。
  static Future<Map<String, dynamic>> discoverAgentModels(
      dynamic arguments) async {
    try {
      final provider = (arguments['provider'] as String? ?? '').trim();
      final baseURL = (arguments['baseURL'] as String? ?? '').trim();
      final apiKey = (arguments['apiKey'] as String? ?? '').trim();
      final apiType = (arguments['apiType'] as String? ?? '').trim();
      if (provider.isEmpty ||
          baseURL.isEmpty ||
          apiKey.isEmpty ||
          apiType.isEmpty) {
        return {
          'success': false,
          'error': 'provider, baseURL, apiKey and apiType are required',
        };
      }
      await (await AIRepository().getApi()).discoverAgentAccountModels(
        <String, dynamic>{
          'provider': provider,
          'baseURL': baseURL,
          'apiKey': apiKey,
          'apiType': apiType,
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('discoverAgentModels failed: $e');
      return _err(e);
    }
  }

  /// 创建 MCP 服务器。参数：
  /// `{name, type, command, protocol, url, outputTransport, containerName,
  ///   port: int 必填, ssePath?, streamableHttpPath?, gatewayImage?, hostIP?}`。
  /// POST /ai/mcp/server。契约 url 映射 McpServerCreate.baseUrl；
  /// protocol/gatewayImage 在底层模型无对应字段，按实际能力丢弃。
  static Future<Map<String, dynamic>> createMcpServerNative(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final type = (arguments['type'] as String? ?? '').trim();
      final command = (arguments['command'] as String? ?? '').trim();
      final outputTransport =
          (arguments['outputTransport'] as String? ?? '').trim();
      final baseUrl = (arguments['url'] as String? ?? '').trim();
      final containerName = (arguments['containerName'] as String? ?? '').trim();
      final port = int.tryParse('${arguments['port'] ?? ''}');
      if (name.isEmpty || command.isEmpty) {
        return {'success': false, 'error': 'name and command are required'};
      }
      if (type.isEmpty ||
          outputTransport.isEmpty ||
          baseUrl.isEmpty ||
          containerName.isEmpty ||
          port == null) {
        return {
          'success': false,
          'error':
              'type, url, outputTransport, containerName and port are required',
        };
      }
      await (await AIRepository().getApi()).createMcpServer(McpServerCreate(
        name: name,
        type: type,
        command: command,
        outputTransport: outputTransport,
        baseUrl: baseUrl,
        containerName: containerName,
        port: port,
        ssePath: arguments['ssePath'] as String?,
        streamableHttpPath: arguments['streamableHttpPath'] as String?,
        hostIP: arguments['hostIP'] as String?,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('createMcpServerNative failed: $e');
      return _err(e);
    }
  }

  /// 删除 MCP 服务器。参数：`{id: int}`。POST /ai/mcp/server/del。
  static Future<Map<String, dynamic>> deleteMcpServerNative(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await (await AIRepository().getApi())
          .deleteMcpServer(McpServerDelete(id: id));
      return _ok();
    } catch (e) {
      appLogger.e('deleteMcpServerNative failed: $e');
      return _err(e);
    }
  }

  static const Set<String> _mcpOperations = {'start', 'stop', 'restart'};

  /// MCP 服务器操作。参数：`{id: int, operate: 'start'|'stop'|'restart'}`。
  /// POST /ai/mcp/server/op。
  static Future<Map<String, dynamic>> operateMcpServerNative(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      final operate = (arguments['operate'] as String? ?? '').trim();
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      if (!_mcpOperations.contains(operate)) {
        return {'success': false, 'error': 'Unsupported operation: $operate'};
      }
      await (await AIRepository().getApi())
          .operateMcpServer(McpServerOperate(id: id, operate: operate));
      return _ok();
    } catch (e) {
      appLogger.e('operateMcpServerNative failed: $e');
      return _err(e);
    }
  }

  /// 测试 MCP 服务器连通性。参数：`{id: int}`。
  /// POST /ai/mcp/server/connection/test。服务端在 200 响应体内回执
  /// `{success, message}`（对齐上游前端语义）：连接失败映射为
  /// `{success: false, error: message}` 而非误报成功。
  static Future<Map<String, dynamic>> testMcpConnection(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      final result = await (await AIRepository().getApi())
          .testMcpServerConnection(<String, dynamic>{'id': id});
      final data = result.data;
      if (data != null && data['success'] == false) {
        return {
          'success': false,
          'error': data['message']?.toString() ?? 'connection test failed',
        };
      }
      return _ok();
    } catch (e) {
      appLogger.e('testMcpConnection failed: $e');
      return _err(e);
    }
  }

  /// 批量同步 MCP 服务器状态。参数：`{ids: int[]}`。
  /// POST /ai/mcp/server/status/sync（上游契约 body `{ids: number[]}`）。
  static Future<Map<String, dynamic>> syncMcpStatus(
      dynamic arguments) async {
    try {
      final ids = (arguments['ids'] as List?)
              ?.map((e) => int.tryParse('$e'))
              .whereType<int>()
              .toList() ??
          <int>[];
      if (ids.isEmpty) {
        return {'success': false, 'error': 'ids is required'};
      }
      await (await AIRepository().getApi())
          .syncMcpServerStatus(<String, dynamic>{'ids': ids});
      return _ok();
    } catch (e) {
      appLogger.e('syncMcpStatus failed: $e');
      return _err(e);
    }
  }

  /// 创建智能体实例（服务端长耗时任务）。参数：
  /// `{agentType, name, appVersion, webUIPort: int 必填, remark?}`。
  /// POST /ai/agents。非必填字段对齐 MDUI3 createAgentSimple 已验证
  /// 默认值（advanced/allowPort/restartPolicy 及 openclaw allowedOrigins）；
  /// 契约 remark 在 AgentCreateReq 无对应字段，按底层实际能力丢弃。
  static Future<Map<String, dynamic>> createAgentNative(
      dynamic arguments) async {
    try {
      final agentType = (arguments['agentType'] as String? ?? '').trim();
      final name = (arguments['name'] as String? ?? '').trim();
      final appVersion = (arguments['appVersion'] as String? ?? '').trim();
      final webUIPort = int.tryParse('${arguments['webUIPort'] ?? ''}');
      if (agentType.isEmpty || name.isEmpty) {
        return {'success': false, 'error': 'agentType and name are required'};
      }
      if (appVersion.isEmpty || webUIPort == null) {
        return {
          'success': false,
          'error': 'appVersion and webUIPort are required',
        };
      }
      await (await AIRepository().getApi()).createAgent(AgentCreateReq(
        name: name,
        appVersion: appVersion,
        webUIPort: webUIPort,
        // openclaw 内嵌 Web UI 需限制 CORS 来源（同 MDUI3 创建语义）。
        allowedOrigins: agentType == 'openclaw'
            ? <String>['http://127.0.0.1:$webUIPort']
            : null,
        agentType: agentType,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        advanced: true,
        containerName: '',
        allowPort: true,
        specifyIP: '',
        restartPolicy: 'unless-stopped',
        cpuQuota: 0,
        memoryLimit: 0,
        memoryUnit: 'M',
        pullImage: true,
        editCompose: false,
        dockerCompose: '',
      ));
      return _ok();
    } catch (e) {
      appLogger.e('createAgentNative failed: $e');
      return _err(e);
    }
  }

  /// 删除智能体实例。参数：`{id: int, forceDelete?: bool}`。
  /// POST /ai/agents/delete。
  static Future<Map<String, dynamic>> deleteAgentNative(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments['id'] ?? ''}');
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      await (await AIRepository().getApi()).deleteAgent(AgentDeleteReq(
        id: id,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        forceDelete: arguments['forceDelete'] as bool? ?? false,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('deleteAgentNative failed: $e');
      return _err(e);
    }
  }

  /// 加载 Ollama 模型。参数：`{name: String}`。POST /ai/ollama/model/load。
  static Future<Map<String, dynamic>> loadOllamaModelNative(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await AIRepository().loadOllamaModel(
        name: name,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      return _ok();
    } catch (e) {
      appLogger.e('loadOllamaModelNative failed: $e');
      return _err(e);
    }
  }

  /// 关闭 Ollama 模型连接。参数：`{name: String}`。POST /ai/ollama/close。
  static Future<Map<String, dynamic>> closeOllamaModelNative(
      dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return {'success': false, 'error': 'name is required'};
      }
      await AIRepository().closeOllamaModel(
        name: name,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      return _ok();
    } catch (e) {
      appLogger.e('closeOllamaModelNative failed: $e');
      return _err(e);
    }
  }

  /// 同步 Ollama 模型列表。参数：`{}`。POST /ai/ollama/model/sync。
  static Future<Map<String, dynamic>> syncOllamaModelsNative(
      dynamic arguments) async {
    try {
      await AIRepository().syncOllamaModels();
      return _ok();
    } catch (e) {
      appLogger.e('syncOllamaModelsNative failed: $e');
      return _err(e);
    }
  }

  // ── 虚拟机 ──────────────────────────────────────────────────────────────

  /// 启用虚拟机运行环境。参数：`{}`。
  static Future<Map<String, dynamic>> enableVmEnvironment(
      dynamic arguments) async {
    try {
      await VMService().enableEnvironment();
      return _ok();
    } catch (e) {
      appLogger.e('enableVmEnvironment failed: $e');
      return _err(e);
    }
  }

  /// 同步虚拟机列表。参数：`{}`。POST /vms/sync。
  static Future<Map<String, dynamic>> syncVms(dynamic arguments) async {
    try {
      await VMService().syncVMs();
      return _ok();
    } catch (e) {
      appLogger.e('syncVms failed: $e');
      return _err(e);
    }
  }

  /// 虚拟机电源操作。参数：`{name: String, operate: start|shutdown|reboot|suspend|resume|destroy}`
  static Future<Map<String, dynamic>> operateVm(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      final operate = (arguments?['operate'] as String? ?? '').trim();
      const allowed = <String>{
        'start',
        'shutdown',
        'reboot',
        'suspend',
        'resume',
        'destroy',
      };
      if (name.isEmpty || !allowed.contains(operate)) {
        return <String, dynamic>{
          'success': false,
          'error': 'name and a supported operate value are required',
        };
      }
      await VMService().operateVM(name, operate);
      return _ok();
    } catch (e) {
      appLogger.e('operateVm failed: $e');
      return _err(e);
    }
  }

  /// 创建虚拟机快照。参数：`{name: String, snapshotName: String, description?: String}`
  static Future<Map<String, dynamic>> createVmSnapshot(
      dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      final snapshotName = (arguments?['snapshotName'] as String? ?? '').trim();
      if (name.isEmpty || snapshotName.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'name and snapshotName are required',
        };
      }
      await VMService().createSnapshot(
        VMSnapshotReq(
          name: name,
          snapshotName: snapshotName,
          description: (arguments?['description'] as String? ?? '').trim(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createVmSnapshot failed: $e');
      return _err(e);
    }
  }

  /// 恢复虚拟机快照。参数：`{name: String, snapshotName: String}`
  static Future<Map<String, dynamic>> recoverVmSnapshot(
      dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      final snapshotName = (arguments?['snapshotName'] as String? ?? '').trim();
      if (name.isEmpty || snapshotName.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'name and snapshotName are required',
        };
      }
      await VMService().recoverSnapshot(
        VMSnapshotReq(name: name, snapshotName: snapshotName),
      );
      return _ok();
    } catch (e) {
      appLogger.e('recoverVmSnapshot failed: $e');
      return _err(e);
    }
  }

  /// 删除虚拟机快照。参数：`{name: String, snapshotName: String}`
  static Future<Map<String, dynamic>> deleteVmSnapshot(
      dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      final snapshotName = (arguments?['snapshotName'] as String? ?? '').trim();
      if (name.isEmpty || snapshotName.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'name and snapshotName are required',
        };
      }
      await VMService().deleteSnapshot(
        VMSnapshotReq(name: name, snapshotName: snapshotName),
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteVmSnapshot failed: $e');
      return _err(e);
    }
  }

  // ── 告警中心 ────────────────────────────────────────────────────────────

  /// 创建告警任务。参数：
  /// `{type, title, methods: [String], cycle?, count?, interval?, sendCount?, advancedParams?}`
  static Future<Map<String, dynamic>> createAlertRule(dynamic arguments) async {
    try {
      final fields = _alertRuleFields(arguments, requireId: false);
      if (fields is Map<String, dynamic>) return fields;
      final input = fields as _AlertRuleInput;
      await AlertService().createAlert(AlertCreate(
        type: input.type,
        method: input.method,
        cycle: input.cycle,
        count: input.count,
        interval: input.interval,
        status: 'Enable',
        title: input.title,
        sendCount: input.sendCount,
        advancedParams: input.advancedParams,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('createAlertRule failed: $e');
      return _err(e);
    }
  }

  /// 更新告警任务。参数在创建参数基础上增加 `{id: int, status?: String}`。
  static Future<Map<String, dynamic>> updateAlertRule(dynamic arguments) async {
    try {
      final fields = _alertRuleFields(arguments, requireId: true);
      if (fields is Map<String, dynamic>) return fields;
      final input = fields as _AlertRuleInput;
      await AlertService().updateAlert(AlertUpdate(
        id: input.id!,
        type: input.type,
        method: input.method,
        cycle: input.cycle,
        count: input.count,
        interval: input.interval,
        title: input.title,
        sendCount: input.sendCount,
        advancedParams: input.advancedParams,
        status: (arguments['status'] as String? ?? '').trim().isEmpty
            ? null
            : (arguments['status'] as String).trim(),
      ));
      return _ok();
    } catch (e) {
      appLogger.e('updateAlertRule failed: $e');
      return _err(e);
    }
  }

  /// 删除告警任务。参数：`{id: int}`。
  static Future<Map<String, dynamic>> deleteAlertRule(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      await AlertService().deleteAlert(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteAlertRule failed: $e');
      return _err(e);
    }
  }

  /// 启用或停用告警任务。参数：`{id: int, enable: bool}`。
  static Future<Map<String, dynamic>> toggleAlertRule(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      final enable = arguments?['enable'] as bool? ?? false;
      await AlertService().updateAlertStatus(id, enable ? 'Enable' : 'Disable');
      return _ok();
    } catch (e) {
      appLogger.e('toggleAlertRule failed: $e');
      return _err(e);
    }
  }

  /// 清空告警日志。参数：`{}`。
  static Future<Map<String, dynamic>> cleanAlertLogs(dynamic arguments) async {
    try {
      await AlertService().cleanLogs();
      return _ok();
    } catch (e) {
      appLogger.e('cleanAlertLogs failed: $e');
      return _err(e);
    }
  }

  /// 保存通知渠道。参数：
  /// `{id?, type, title, status?, sender?, userName?, password?, passwordAction?,
  ///   host?, port?, encryption?, recipient?, webhookUrl?, preset?, bodyType?,
  ///   template?, headers?: [{key,value}], formPairs?: [{key,value}]}`
  static Future<Map<String, dynamic>> saveAlertChannel(
      dynamic arguments) async {
    try {
      final type = (arguments?['type'] as String? ?? '').trim();
      final title = (arguments?['title'] as String? ?? '').trim();
      if (type.isEmpty || title.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'type and title are required',
        };
      }
      final id = int.tryParse('${arguments?['id'] ?? 0}') ?? 0;
      final config = alertChannelConfig(arguments as Map);
      await AlertService().saveConfig(AlertConfigUpdate(
        id: id,
        type: type,
        title: title,
        config: jsonEncode(config),
        status: (arguments['status'] as String? ?? 'Enable').trim(),
        displayName: title,
      ));
      return _ok();
    } catch (e) {
      appLogger.e('saveAlertChannel failed: $e');
      return _err(e);
    }
  }

  /// 删除通知渠道。参数：`{id: int}`。
  static Future<Map<String, dynamic>> deleteAlertChannel(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      await AlertService().deleteConfig(id);
      return _ok();
    } catch (e) {
      appLogger.e('deleteAlertChannel failed: $e');
      return _err(e);
    }
  }

  /// 启用或停用通知渠道。参数：`{id: int, enable: bool}`。
  static Future<Map<String, dynamic>> toggleAlertChannel(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      final enable = arguments?['enable'] as bool? ?? false;
      await AlertService().updateConfigStatus(id, enable ? 'Enable' : 'Disable');
      return _ok();
    } catch (e) {
      appLogger.e('toggleAlertChannel failed: $e');
      return _err(e);
    }
  }

  /// 测试通知渠道。参数与保存渠道相同。
  ///
  /// 返回 `success` 表示测试是否通过，`message` 与 `response` 为服务端结果。
  static Future<Map<String, dynamic>> testAlertChannel(
      dynamic arguments) async {
    try {
      final type = (arguments?['type'] as String? ?? '').trim();
      if (type.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'type is required'};
      }
      final request = alertChannelTestRequest(arguments as Map);
      final result = await AlertService().testConfig(request);
      return alertConfigTestResultPayload(result);
    } catch (e) {
      appLogger.e('testAlertChannel failed: $e');
      return _err(e);
    }
  }

  /// 校验并解析告警任务表单字段。
  ///
  /// 返回记录时字段顺序为：type、method、cycle、count、interval、title、
  /// sendCount、advancedParams、id；校验失败时直接返回失败结构。
  static Object _alertRuleFields(
    dynamic arguments, {
    required bool requireId,
  }) {
    final type = (arguments?['type'] as String? ?? '').trim();
    final title = (arguments?['title'] as String? ?? '').trim();
    final methods = (arguments?['methods'] as List?)
            ?.map((method) => '$method'.trim())
            .where((method) => method.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final id = int.tryParse('${arguments?['id'] ?? ''}');
    if (type.isEmpty || title.isEmpty || methods.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'error': 'type, title and methods are required',
      };
    }
    if (requireId && (id == null || id <= 0)) {
      return <String, dynamic>{'success': false, 'error': 'id is required'};
    }
    final cycle = int.tryParse('${arguments?['cycle'] ?? ''}');
    final count = int.tryParse('${arguments?['count'] ?? ''}');
    final interval = int.tryParse('${arguments?['interval'] ?? ''}');
    final sendCount = int.tryParse('${arguments?['sendCount'] ?? ''}');
    final advancedParams =
        (arguments?['advancedParams'] as String? ?? '').trim();
    return _AlertRuleInput(
      type: type,
      method: methods.join(','),
      cycle: AlertRuleTypes.needsCycleDays(type) ? cycle : null,
      count: AlertRuleTypes.needsThreshold(type) ? count : null,
      interval: AlertRuleTypes.needsInterval(type) ? interval : null,
      title: title,
      sendCount: sendCount ?? 1,
      advancedParams: advancedParams.isEmpty ? null : advancedParams,
      id: id,
    );
  }

  // ── 模型下载器 ──────────────────────────────────────────────────────────

  /// 同步推荐模型目录。参数：`{}`。
  static Future<Map<String, dynamic>> syncModelDownloaderFeatured(
      dynamic arguments) async {
    try {
      await ModelDownloaderService().syncFeatured();
      return _ok();
    } catch (e) {
      appLogger.e('syncModelDownloaderFeatured failed: $e');
      return _err(e);
    }
  }

  /// 切换推荐模型自动同步。参数：`{enabled: bool}`。
  static Future<Map<String, dynamic>> setModelDownloaderFeaturedSync(
      dynamic arguments) async {
    try {
      final enabled = arguments?['enabled'] as bool? ?? false;
      await ModelDownloaderService().updateFeaturedSyncStatus(enabled);
      return _ok();
    } catch (e) {
      appLogger.e('setModelDownloaderFeaturedSync failed: $e');
      return _err(e);
    }
  }

  /// 提交下载。参数：`{repoID, source: hf|modelScope, downloadType?, revision?}`
  static Future<Map<String, dynamic>> downloadModel(dynamic arguments) async {
    try {
      final repoID = (arguments?['repoID'] as String? ?? '').trim();
      final source = (arguments?['source'] as String? ?? 'hf').trim();
      if (repoID.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'repoID is required'};
      }
      final revision = (arguments?['revision'] as String? ?? '').trim();
      final downloadType =
          (arguments?['downloadType'] as String? ?? 'all').trim();
      final service = ModelDownloaderService();
      if (source == 'hf') {
        await service.downloadHuggingFace(
          repoID: repoID,
          revision: revision.isEmpty ? null : revision,
          downloadType: downloadType,
        );
      } else {
        await service.downloadModelScope(
          repoID: repoID,
          revision: revision.isEmpty ? null : revision,
          downloadType: downloadType,
        );
      }
      return _ok();
    } catch (e) {
      appLogger.e('downloadModel failed: $e');
      return _err(e);
    }
  }

  /// 取消下载任务。参数：`{id: int, withFile?: bool}`
  static Future<Map<String, dynamic>> cancelModelTask(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      await ModelDownloaderService().cancelTask(
        id,
        withFile: arguments?['withFile'] as bool? ?? false,
      );
      return _ok();
    } catch (e) {
      appLogger.e('cancelModelTask failed: $e');
      return _err(e);
    }
  }

  /// 重试下载任务。参数：`{id: int}`。
  static Future<Map<String, dynamic>> retryModelTask(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      await ModelDownloaderService().retryTask(id);
      return _ok();
    } catch (e) {
      appLogger.e('retryModelTask failed: $e');
      return _err(e);
    }
  }

  /// 移除下载任务记录。参数：`{id: int, withFile?: bool}`
  static Future<Map<String, dynamic>> removeModelTask(
      dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      await ModelDownloaderService().removeTask(
        id,
        withFile: arguments?['withFile'] as bool?,
      );
      return _ok();
    } catch (e) {
      appLogger.e('removeModelTask failed: $e');
      return _err(e);
    }
  }

  /// 删除本地模型。参数：`{name, downloadType?, withFile?: bool}`
  static Future<Map<String, dynamic>> deleteLocalModel(
      dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'name is required'};
      }
      final downloadType = (arguments?['downloadType'] as String? ?? '').trim();
      await ModelDownloaderService().deleteLocalModel(
        name: name,
        downloadType: downloadType.isEmpty ? null : downloadType,
        withFile: arguments?['withFile'] as bool? ?? true,
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteLocalModel failed: $e');
      return _err(e);
    }
  }

  /// 保存下载设置。参数：
  /// `{modelDir, featuredSync: bool, hfEndpoint?, hfToken?, modelScopeEndpoint?, modelScopeToken?}`
  static Future<Map<String, dynamic>> updateModelDownloaderSettings(
      dynamic arguments) async {
    try {
      final modelDir = (arguments?['modelDir'] as String? ?? '').trim();
      if (modelDir.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'modelDir is required',
        };
      }
      final featuredSync = arguments?['featuredSync'] as bool? ?? true;
      await ModelDownloaderService().updateSettings(
        ModelDownloaderSetting(
          modelDir: modelDir,
          featuredModelsSync: featuredSync ? 'Enable' : 'Disable',
          hfEndpoint: (arguments?['hfEndpoint'] as String? ?? '').trim(),
          hfToken: (arguments?['hfToken'] as String? ?? '').trim(),
          modelScopeEndpoint:
              (arguments?['modelScopeEndpoint'] as String? ?? '').trim(),
          modelScopeToken:
              (arguments?['modelScopeToken'] as String? ?? '').trim(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateModelDownloaderSettings failed: $e');
      return _err(e);
    }
  }

  // ── 监控中心 ────────────────────────────────────────────────────────────

  /// 保存监控设置。参数：
  /// `{enabled: bool, interval: int, retention: int, defaultNetwork?: String, defaultIO?: String}`
  static Future<Map<String, dynamic>> updateMonitoringSettings(
      dynamic arguments) async {
    try {
      final interval = int.tryParse('${arguments?['interval'] ?? ''}');
      final retention = int.tryParse('${arguments?['retention'] ?? ''}');
      if (interval == null || interval <= 0 || retention == null || retention <= 0) {
        return <String, dynamic>{
          'success': false,
          'error': 'interval and retention must be positive',
        };
      }
      final updated = await MonitoringService().updateSetting(
        interval: interval,
        retention: retention,
        enabled: arguments?['enabled'] as bool? ?? false,
        defaultNetwork:
            (arguments?['defaultNetwork'] as String? ?? '').trim().isEmpty
                ? null
                : (arguments?['defaultNetwork'] as String).trim(),
        defaultIO: (arguments?['defaultIO'] as String? ?? '').trim().isEmpty
            ? null
            : (arguments?['defaultIO'] as String).trim(),
      );
      if (!updated) {
        return <String, dynamic>{
          'success': false,
          'error': 'monitor settings were not saved',
        };
      }
      return _ok();
    } catch (e) {
      appLogger.e('updateMonitoringSettings failed: $e');
      return _err(e);
    }
  }

  /// 清理监控历史数据。参数：`{}`。
  static Future<Map<String, dynamic>> cleanMonitoringData(
      dynamic arguments) async {
    try {
      final cleaned = await MonitoringService().cleanData();
      if (!cleaned) {
        return <String, dynamic>{
          'success': false,
          'error': 'monitor data was not cleaned',
        };
      }
      return _ok();
    } catch (e) {
      appLogger.e('cleanMonitoringData failed: $e');
      return _err(e);
    }
  }

  // ── 防火墙深度操作 ──────────────────────────────────────────────────────

  /// 防火墙启停重启。参数：`{operation: start|stop|restart, withDockerRestart?: bool}`
  static Future<Map<String, dynamic>> operateFirewall(dynamic arguments) async {
    try {
      final operation = (arguments?['operation'] as String? ?? '').trim();
      const allowed = <String>{'start', 'stop', 'restart'};
      if (!allowed.contains(operation)) {
        return <String, dynamic>{
          'success': false,
          'error': 'Unsupported operation: $operation',
        };
      }
      await FirewallService().operateFirewall(
        operation: FirewallOperation(
          operation: operation,
          withDockerRestart: arguments?['withDockerRestart'] as bool? ?? false,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('operateFirewall failed: $e');
      return _err(e);
    }
  }

  /// 更新端口规则。参数：`{oldRule: Map, newRule: Map}`。
  static Future<Map<String, dynamic>> updateFirewallPortRule(
      dynamic arguments) async {
    try {
      await FirewallService().updatePortRule(
        firewallPortUpdateRequest(arguments as Map),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateFirewallPortRule failed: $e');
      return _err(e);
    }
  }

  /// 更新 IP 规则。参数：`{oldRule: Map, newRule: Map}`。
  static Future<Map<String, dynamic>> updateFirewallIpRule(
      dynamic arguments) async {
    try {
      await FirewallService().updateIpRule(
        firewallIpUpdateRequest(arguments as Map),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateFirewallIpRule failed: $e');
      return _err(e);
    }
  }

  /// 更新规则描述。参数：
  /// `{type: port|ip, description, chain?, srcIP?, dstIP?, srcPort?, dstPort?, protocol?, strategy?}`
  static Future<Map<String, dynamic>> updateFirewallRuleDescription(
      dynamic arguments) async {
    try {
      await FirewallService().updateDescription(
        firewallDescriptionUpdate(arguments as Map),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateFirewallRuleDescription failed: $e');
      return _err(e);
    }
  }

  // ── 运行环境操作 ────────────────────────────────────────────────────────

  /// 运行环境启停重启。参数：`{id: int, operation: start|stop|restart}`
  static Future<Map<String, dynamic>> operateRuntime(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      final operation = (arguments?['operation'] as String? ?? '').trim();
      const allowed = <String>{'start', 'stop', 'restart'};
      if (id == null || id <= 0) {
        return <String, dynamic>{'success': false, 'error': 'id is required'};
      }
      if (!allowed.contains(operation)) {
        return <String, dynamic>{
          'success': false,
          'error': 'Unsupported operation: $operation',
        };
      }
      await RuntimeService().operateRuntime(id, operation);
      return _ok();
    } catch (e) {
      appLogger.e('operateRuntime failed: $e');
      return _err(e);
    }
  }

  // ── 防火墙 V2 写入 ──────────────────────────────────────────────────────

  /// 启用转发。参数：`{taskID?, backupFile?}`
  static Future<Map<String, dynamic>> enableFirewallForward(
      dynamic arguments) async {
    try {
      await (await _firewallV2Api()).enableFirewallForwarding(
        FirewallForwardEnableRequest(
          taskID: (arguments?['taskID'] as String? ?? '').trim().isEmpty
              ? null
              : arguments?['taskID'] as String,
          backupFile: (arguments?['backupFile'] as String? ?? '').trim().isEmpty
              ? null
              : arguments?['backupFile'] as String,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('enableFirewallForward failed: $e');
      return _err(e);
    }
  }

  /// 转发规则操作。参数：`{rules: [Map], import?: bool}`
  static Future<Map<String, dynamic>> operateFirewallForwardRules(
      dynamic arguments) async {
    try {
      final rules = (arguments?['rules'] as List?)
              ?.whereType<Map>()
              .map((rule) => rule.cast<String, dynamic>())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[];
      if (rules.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'rules are required'};
      }
      await (await _firewallV2Api()).operateFirewallForwardRules(
        FirewallForwardOperateV2Request(
          rules: rules,
          import: arguments?['import'] as bool?,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('operateFirewallForwardRules failed: $e');
      return _err(e);
    }
  }

  /// Docker 端口守卫操作。参数：`{operation: initialize|bind|unbind, taskID?, backupFile?}`
  static Future<Map<String, dynamic>> operateFirewallDockerGuard(
      dynamic arguments) async {
    try {
      final operation = (arguments?['operation'] as String? ?? '').trim();
      const allowed = <String>{'initialize', 'bind', 'unbind'};
      if (!allowed.contains(operation)) {
        return <String, dynamic>{
          'success': false,
          'error': 'Unsupported operation: $operation',
        };
      }
      await (await _firewallV2Api()).operateFirewallDockerGuard(
        FirewallDockerOperation(
          operation: operation,
          taskID: (arguments?['taskID'] as String? ?? '').trim().isEmpty
              ? null
              : arguments?['taskID'] as String,
          backupFile: (arguments?['backupFile'] as String? ?? '').trim().isEmpty
              ? null
              : arguments?['backupFile'] as String,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('operateFirewallDockerGuard failed: $e');
      return _err(e);
    }
  }

  /// Docker 端口策略批量写入。参数：`{policies: [Map], import?: bool}`
  static Future<Map<String, dynamic>> upsertFirewallDockerPolicies(
      dynamic arguments) async {
    try {
      final policies = (arguments?['policies'] as List?)
              ?.whereType<Map>()
              .map((policy) => policy.cast<String, dynamic>())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[];
      if (policies.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'policies are required',
        };
      }
      await (await _firewallV2Api()).batchUpsertFirewallDockerPolicies(
        FirewallDockerPolicyBatch(
          policies: policies,
          import: arguments?['import'] as bool?,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('upsertFirewallDockerPolicies failed: $e');
      return _err(e);
    }
  }

  /// Docker 端口策略批量删除。参数：`{uuids: [String]}`
  static Future<Map<String, dynamic>> deleteFirewallDockerPolicies(
      dynamic arguments) async {
    try {
      final uuids = (arguments?['uuids'] as List?)
              ?.map((uuid) => '$uuid'.trim())
              .where((uuid) => uuid.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (uuids.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'uuids are required'};
      }
      await (await _firewallV2Api()).batchDeleteFirewallDockerPolicies(
        FirewallDockerPolicyBatchDelete(uuids: uuids),
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteFirewallDockerPolicies failed: $e');
      return _err(e);
    }
  }

  /// IPv6 防火墙开关。参数：`{enabled: bool}`
  static Future<Map<String, dynamic>> updateFirewallIPv6(
      dynamic arguments) async {
    try {
      final enabled = arguments?['enabled'] as bool? ?? false;
      await (await _firewallV2Api()).updateFirewallIPv6(
        FirewallIPv6Operation(status: enabled ? 'Enable' : 'Disable'),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateFirewallIPv6 failed: $e');
      return _err(e);
    }
  }

  /// 防火墙后端操作。参数：`{backend, operation, subsystem}`
  static Future<Map<String, dynamic>> operateFirewallBackend(
      dynamic arguments) async {
    try {
      final backend = (arguments?['backend'] as String? ?? '').trim();
      final operation = (arguments?['operation'] as String? ?? '').trim();
      final subsystem = (arguments?['subsystem'] as String? ?? '').trim();
      if (backend.isEmpty || operation.isEmpty || subsystem.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error': 'backend, operation and subsystem are required',
        };
      }
      await (await _firewallV2Api()).operateFirewallBackend(
        FirewallBackendOperation(
          backend: backend,
          operation: operation,
          subsystem: subsystem,
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('operateFirewallBackend failed: $e');
      return _err(e);
    }
  }

  /// 创建端口白名单。参数：`{rule: Map}`
  static Future<Map<String, dynamic>> createFirewallWhitelist(
      dynamic arguments) async {
    try {
      final rule = _whitelistRule(arguments?['rule']);
      await (await _firewallV2Api()).createFirewallPortWhitelist(
        FirewallPortWhitelistOperation(rule: rule),
      );
      return _ok();
    } catch (e) {
      appLogger.e('createFirewallWhitelist failed: $e');
      return _err(e);
    }
  }

  /// 更新端口白名单。参数：`{oldRule: Map, rule: Map}`
  static Future<Map<String, dynamic>> updateFirewallWhitelist(
      dynamic arguments) async {
    try {
      await (await _firewallV2Api()).updateFirewallPortWhitelist(
        FirewallPortWhitelistUpdate(
          oldRule: _whitelistRule(arguments?['oldRule']),
          rule: _whitelistRule(arguments?['rule']),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateFirewallWhitelist failed: $e');
      return _err(e);
    }
  }

  /// 删除端口白名单。参数：`{rule: Map}`
  static Future<Map<String, dynamic>> deleteFirewallWhitelist(
      dynamic arguments) async {
    try {
      await (await _firewallV2Api()).deleteFirewallPortWhitelist(
        FirewallPortWhitelistOperation(rule: _whitelistRule(arguments?['rule'])),
      );
      return _ok();
    } catch (e) {
      appLogger.e('deleteFirewallWhitelist failed: $e');
      return _err(e);
    }
  }

  static Future<FirewallV2Api> _firewallV2Api() async =>
      FirewallV2Api(await ApiClientManager.instance.getCurrentClient());

  static FirewallPortWhitelistRule _whitelistRule(Object? value) {
    final map = value is Map ? value : const <String, dynamic>{};
    return FirewallPortWhitelistRule(
      port: '${map['port'] ?? ''}',
      protocol: '${map['protocol'] ?? 'tcp'}',
      type: '${map['type'] ?? ''}'.isEmpty ? null : '${map['type']}',
      sources: (map['sources'] as List?)
          ?.map((source) => '$source')
          .toList(growable: false),
    );
  }

  // ── 内部工具 ──────────────────────────────────────────────────────────────

  /// 将 dynamic 类型的 id 安全转换为 int（支持 int 和 String 输入）。
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return int.parse(value.toString());
  }
}

/// 告警任务表单校验后的字段集合。
class _AlertRuleInput {
  const _AlertRuleInput({
    required this.type,
    required this.method,
    required this.title,
    required this.sendCount,
    this.cycle,
    this.count,
    this.interval,
    this.advancedParams,
    this.id,
  });

  final String type;
  final String method;
  final String title;
  final int sendCount;
  final int? cycle;
  final int? count;
  final int? interval;
  final String? advancedParams;
  final int? id;
}
