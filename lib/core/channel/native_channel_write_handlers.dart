import '../../features/ai/ai_repository.dart';
import '../../api/v2/website_v2.dart';
import '../../features/apps/app_service.dart';
import '../../features/commands/services/command_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../../features/group/services/group_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/containers/container_service.dart';
import '../../features/databases/databases_service.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/openresty/services/openresty_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';
import '../../features/settings/panel_ssl/services/panel_ssl_service.dart';
import '../../features/websites/services/website_certificate_service.dart';

import '../../features/toolbox/services/toolbox_device_service.dart';
import '../../data/models/app_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../data/repositories/cronjob_form_repository.dart';
import '../../data/models/cronjob_form_request_models.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/firewall/firewall_service.dart';
import '../../features/server/server_repository.dart';
import '../../features/websites/services/websites_service.dart';
import '../../data/models/website_models.dart';
import '../../data/models/website_ssl_crud_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../core/config/api_config.dart';
import '../../core/services/app_preferences_service.dart';
import '../../core/theme/ui_render_mode.dart';
import '../../data/models/backup_account_models.dart';
import '../../data/models/firewall_models.dart';
import '../../features/backups/services/backup_recover_service.dart';
import '../../data/models/backup_request_models.dart';
import '../../data/models/database_models.dart';
import '../../data/models/container_compose_models.dart';
import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../services/logger/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show Locale;

/// 统一返回结构：成功 `{success: true}`，失败 `{success: false, error: String}`。
Map<String, dynamic> _ok() => {'success': true};
Map<String, dynamic> _err(Object e) => {'success': false, 'error': e.toString()};

/// B1 网站配置中心写通道使用的网站 V2 API（按需构造）。
Future<WebsiteV2Api> _websiteApi() async =>
    WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());

/// 所有 Native Channel 写操作 handlers 的集中实现。
/// 被 [NativeChannelManager] 的 dispatch switch 调用。
class NativeChannelWriteHandlers {
  // ── 服务器 ────────────────────────────────────────────────────────────────

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
  /// 参数：`{appKey: String 必填, version?: String(默认取 versions 第一个),
  ///   name?: String(默认 appKey)}`
  /// 返回：`{success: true, appId: <安装返回 id 或 0>}`。
  static Future<Map<String, dynamic>> installApp(dynamic arguments) async {
    try {
      final appKey = (arguments['appKey'] as String? ?? '').trim();
      if (appKey.isEmpty) {
        return {'success': false, 'error': 'appKey is required'};
      }
      final service = AppService();
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
      // params 取表单字段默认值（等价对话框 _paramControllers 初始化语义）；
      // 无表单字段时不传 params 直接安装。
      final detail = await service.getAppDetail(
        '${app.id}',
        version,
        app.type ?? 'app',
      );
      if (detail.id == null) {
        return {'success': false, 'error': 'app detail not found: $appKey'};
      }
      final paramsMap = <String, dynamic>{};
      for (final field in detail.params?.formFields ?? const <AppFormField>[]) {
        paramsMap[field.envKey] = field.defaultValue?.toString() ?? '';
      }
      final requestedName = (arguments['name'] as String? ?? '').trim();
      final info = await service.installApp(AppInstallCreateRequest(
        appDetailId: detail.id!,
        name: requestedName.isNotEmpty ? requestedName : appKey,
        type: app.type,
        advanced: false,
        memoryUnit: 'MB',
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

  // ── 定时任务（建/改/执行一次，shell 类型最小集） ─────────────────────────

  static CronjobOperateRequest _buildCronjobRequest(dynamic arguments, {int? id}) {
    final name = (arguments['name'] as String? ?? '').trim();
    final spec = (arguments['spec'] as String? ?? '').trim();
    if (name.isEmpty || spec.isEmpty) {
      throw ArgumentError('name and spec are required');
    }
    final script = arguments['script'] as String? ?? '';
    return CronjobOperateRequest(
      id: id,
      name: name,
      groupID: int.tryParse('${arguments['groupID'] ?? 0}') ?? 0,
      type: 'shell',
      specCustom: true,
      spec: spec,
      script: script,
    );
  }

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
      final request = _buildCronjobRequest(arguments, id: id);
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
          await service.deleteCompose(compose);
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
  /// `{name: String 必填, path: String 必填, content: String 必填}`
  static Future<Map<String, dynamic>> updateCompose(dynamic arguments) async {
    try {
      final name = (arguments['name'] as String? ?? '').trim();
      final path = (arguments['path'] as String? ?? '').trim();
      final content = arguments['content'] as String? ?? '';
      if (name.isEmpty || path.isEmpty || content.trim().isEmpty) {
        return {'success': false, 'error': 'name, path and content are required'};
      }
      await OrchestrationService().updateCompose(
        ContainerComposeUpdateRequest(
          name: name,
          path: path,
          content: content,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateCompose failed: $e');
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
          await prefs.saveUIRenderMode(
            value == 'native' ? UIRenderMode.native : UIRenderMode.md3,
          );
          return _ok();
        case 'language':
          await prefs.saveLocale(
            value == null || value == 'system' ? null : Locale(value),
          );
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

  // ── 内部工具 ──────────────────────────────────────────────────────────────

  /// 将 dynamic 类型的 id 安全转换为 int（支持 int 和 String 输入）。
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return int.parse(value.toString());
  }
}
