import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../../api/v2/api_response_parser.dart';
import '../../api/v2/website_v2.dart';
import '../services/logger/logger_service.dart';

/// B1 网站配置中心读通道使用的网站 V2 API（按需构造）。
Future<WebsiteV2Api> _websiteApi() async =>
    WebsiteV2Api(await ApiClientManager.instance.getCurrentClient());

/// 读通道网站深度配置域：HTTPS、代理、重定向、伪静态、CORS、防盗链、
/// BasicAuth、缓存、真实 IP、转发、负载均衡、域名与网站日志。
///
/// 协议单一事实源：docs/development/modules/b1_website_channel_contract.md。
/// 读语义：返回原始解析数据（列表/映射透传，不做字段裁剪），失败返回空。
class NativeChannelWebsiteReadHandlers {
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

  /// 网站负载均衡列表。参数：`{id: int}`。GET /websites/{id}/lbs。
  static Future<dynamic> getWebsiteLoadBalancers(dynamic arguments) async {
    try {
      final id = int.tryParse('${arguments?['id'] ?? ''}');
      if (id == null) {
        return [];
      }
      final items = await (await _websiteApi()).getWebsiteLoadBalancers(id);
      return items
          .map((item) => <String, dynamic>{
                'name': item['name']?.toString() ?? '',
                'algorithm': item['algorithm']?.toString() ?? '',
                'servers': item['servers'] is List ? item['servers'] : const [],
                'content': item['content']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get website load balancers for native: $e');
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
}