import '../../data/models/app_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../features/apps/app_service.dart';
import '../../features/websites/services/websites_service.dart';
import '../services/logger/logger_service.dart';

/// 读通道应用与网站基础域：应用目录、已安装应用、建站预载与网站详情。
class NativeChannelBusinessReadHandlers {
  // ── 应用 ────────────────────────────────────────────────────────────────

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

  // ── 网站基础 ────────────────────────────────────────────────────────────

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
}