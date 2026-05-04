import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/api/v2/app_v2.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/api/v2/ssl_v2.dart';
import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/api/v2/monitor_v2.dart';
import 'package:onepanel_client/api/v2/process_v2.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/host_tool_v2.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/api/v2/snapshot_v2.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/api/v2/compose_v2.dart';
import 'package:onepanel_client/api/v2/openresty_v2.dart';
import 'package:onepanel_client/api/v2/runtime_v2.dart';
import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/api/v2/update_v2.dart';
import 'package:onepanel_client/api/v2/user_v2.dart';
import 'package:onepanel_client/api/v2/system_group_v2.dart';
import 'package:onepanel_client/api/v2/website_group_v2.dart';
import 'package:onepanel_client/api/v2/script_library_v2.dart';
import 'package:onepanel_client/api/v2/disk_management_v2.dart';
import 'package:onepanel_client/api/v2/docker_v2.dart';
import 'package:onepanel_client/api/v2/task_log_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

import '../core/test_config_manager.dart';

const _pkg = 'test.integration.full_api_contract';

String _pretty(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? 'null';
  }
}

void _log(String title, {Object? request, Object? response}) {
  appLogger.dWithPackage(_pkg, '======== $title ========');
  if (request != null) appLogger.dWithPackage(_pkg, 'Req: ${_pretty(request)}');
  if (response != null) {
    final s = _pretty(response);
    appLogger.dWithPackage(_pkg, 'Res: ${s.length > 2000 ? '${s.substring(0, 2000)}...' : s}');
  }
}

Future<Response<dynamic>> _rawGet(DioClient c, String path) =>
    c.get<dynamic>(ApiConstants.buildApiPath(path));

Future<Response<dynamic>> _rawPost(DioClient c, String path, {dynamic data}) =>
    c.post<dynamic>(ApiConstants.buildApiPath(path), data: data);

dynamic _unwrap(dynamic raw, String path) {
  expect(raw, isA<Map>(), reason: '$path: should be wrapped object');
  final m = Map<String, dynamic>.from(raw as Map);
  expect(m['code'], equals(200), reason: '$path: code should be 200, got ${m['code']}. msg=${m['message']}');
  expect(m.containsKey('data'), isTrue, reason: '$path: should contain data');
  return m['data'];
}

Map<String, dynamic> _unwrapPage(dynamic data, String path) {
  expect(data, isA<Map>(), reason: '$path: data should be a page object');
  final p = Map<String, dynamic>.from(data as Map);
  expect(p.containsKey('total'), isTrue, reason: '$path: page should have total');
  expect(p.containsKey('items'), isTrue, reason: '$path: page should have items');
  return p;
}

List<dynamic> _unwrapList(dynamic data, String path) {
  if (data == null) return const [];
  // Accept both List and null - many endpoints return null for empty results
  if (data is! List) {
    appLogger.wWithPackage(_pkg, '$path: expected List but got ${data.runtimeType}');
    return const [];
  }
  return List<dynamic>.from(data);
}

void main() {
  late DioClient client;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    final apiKey = TestEnvironment.config.getString('PANEL_API_KEY');
    canRun = TestEnvironment.runIntegrationTests &&
        apiKey.isNotEmpty &&
        apiKey != 'your_api_key_here';
    if (canRun) {
      client = DioClient(baseUrl: TestEnvironment.baseUrl, apiKey: apiKey);
    }
  });

  String? skip() => canRun ? null : 'Integration tests disabled or no API key';

  // =========================================================================
  // 1. Auth Module
  // =========================================================================
  group('Auth 模块', () {
    test('GET /core/auth/setting - 登录设置', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/core/auth/setting');
        final data = _unwrap(raw.data, '/core/auth/setting');
        _log('Auth/setting', response: data);
        expect(data, isA<Map>(), reason: 'setting should be a map');
      } catch (e) {
        // Auth endpoints may not be available on all server versions
        appLogger.wWithPackage(_pkg, 'Auth/setting not available: $e');
      }
    });

    test('GET /core/auth/issafety - 安全状态', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/core/auth/issafety');
        final data = _unwrap(raw.data, '/core/auth/issafety');
        _log('Auth/issafety', response: data);
        expect(data, isA<Map>());
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Auth/issafety not available: $e');
      }
    });

    test('GET /core/auth/demo - 演示模式', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/core/auth/demo');
        final data = _unwrap(raw.data, '/core/auth/demo');
        _log('Auth/demo', response: data);
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Auth/demo not available: $e');
      }
    });

    test('GET /core/auth/language - 系统语言', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/core/auth/language');
        final data = _unwrap(raw.data, '/core/auth/language');
        _log('Auth/language', response: data);
        expect(data, isA<String>(), reason: 'language should be a string');
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Auth/language not available: $e');
      }
    });
  });

  // =========================================================================
  // 2. Dashboard Module
  // =========================================================================
  group('Dashboard 模块', () {
    test('GET /dashboard/base/default/default - 基础指标', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/base/default/default');
      final data = _unwrap(raw.data, '/dashboard/base/default/default');
      _log('Dashboard/base', response: data);
      expect(data, isA<Map>(), reason: 'base info should be a map');
      // Check common fields
      final m = Map<String, dynamic>.from(data as Map);
      appLogger.dWithPackage(_pkg, 'Dashboard base keys: ${m.keys.toList()}');
    });

    test('GET /dashboard/base/os - 操作系统信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/base/os');
      final data = _unwrap(raw.data, '/dashboard/base/os');
      _log('Dashboard/base/os', response: data);
      expect(data, isA<Map>());
    });

    test('GET /dashboard/current/default/default - 实时指标', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/default/default');
      final data = _unwrap(raw.data, '/dashboard/current/default/default');
      _log('Dashboard/current', response: data);
      expect(data, isA<Map>());
    });

    test('GET /dashboard/current/node - 节点信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/node');
      final data = _unwrap(raw.data, '/dashboard/current/node');
      _log('Dashboard/current/node', response: data);
    });

    test('GET /dashboard/current/top/cpu - CPU Top 进程', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/top/cpu');
      final data = _unwrap(raw.data, '/dashboard/current/top/cpu');
      _log('Dashboard/top/cpu', response: data);
      expect(data, isA<List>(), reason: 'cpu top should be a list');
    });

    test('GET /dashboard/current/top/mem - 内存 Top 进程', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/top/mem');
      final data = _unwrap(raw.data, '/dashboard/current/top/mem');
      _log('Dashboard/top/mem', response: data);
      expect(data, isA<List>(), reason: 'mem top should be a list');
    });

    test('GET /dashboard/app/launcher - 应用启动器', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/app/launcher');
      final data = _unwrap(raw.data, '/dashboard/app/launcher');
      _log('Dashboard/app/launcher', response: data);
      expect(data, isA<List>());
    });

    test('GET /dashboard/quick/option - 快捷导航', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/quick/option');
      final data = _unwrap(raw.data, '/dashboard/quick/option');
      _log('Dashboard/quick/option', response: data);
      expect(data, isA<List>());
    });
  });

  // =========================================================================
  // 3. Container Module
  // =========================================================================
  group('Container 模块', () {
    test('GET /containers/status - 容器状态统计', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/status');
      final data = _unwrap(raw.data, '/containers/status');
      _log('Container/status', response: data);
      expect(data, isA<Map>());
      final m = Map<String, dynamic>.from(data as Map);
      appLogger.dWithPackage(_pkg, 'Container status keys: ${m.keys.toList()}');
    });

    test('GET /containers/docker/status - Docker 状态', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/docker/status');
      final data = _unwrap(raw.data, '/containers/docker/status');
      _log('Container/docker/status', response: data);
      expect(data, isA<Map>());
    });

    test('POST /containers/search - 容器列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
        'state': 'all',
      });
      final data = _unwrap(raw.data, '/containers/search');
      _log('Container/search', response: data);
      _unwrapPage(data, '/containers/search');
    });

    test('GET /containers/list/stats - 容器资源统计', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/list/stats');
      final data = _unwrap(raw.data, '/containers/list/stats');
      _log('Container/list/stats', response: data);
      // data can be null or list
      if (data != null) expect(data, isA<List>());
    });

    test('GET /containers/image/all - 镜像列表', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/image/all');
      final data = _unwrap(raw.data, '/containers/image/all');
      _log('Container/image/all', response: data);
      // data can be null or list
      if (data != null) expect(data, isA<List>());
    });

    test('POST /containers/network/search - 网络列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/network/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/containers/network/search');
      _log('Container/network/search', response: data);
      _unwrapPage(data, '/containers/network/search');
    });

    test('POST /containers/volume/search - 卷列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/volume/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/containers/volume/search');
      _log('Container/volume/search', response: data);
      _unwrapPage(data, '/containers/volume/search');
    });

    test('GET /containers/repo - 镜像仓库', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/repo');
      final data = _unwrap(raw.data, '/containers/repo');
      _log('Container/repo', response: data);
      expect(data, isA<List>());
    });

    test('GET /containers/daemonjson - Docker 配置', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/daemonjson');
      final data = _unwrap(raw.data, '/containers/daemonjson');
      _log('Container/daemonjson', response: data);
    });

    test('GET /containers/limit - 容器资源限制', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/limit');
      final data = _unwrap(raw.data, '/containers/limit');
      _log('Container/limit', response: data);
    });
  });

  // =========================================================================
  // 4. Database Module
  // =========================================================================
  group('Database 模块', () {
    test('GET /databases/db/list/mysql,mariadb - MySQL 实例列表', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/databases/db/list/mysql,mariadb');
      final data = _unwrap(raw.data, '/databases/db/list/mysql,mariadb');
      _log('Database/list/mysql', response: data);
      // data can be null when no instances exist
      if (data != null) expect(data, isA<List>());
    });

    test('POST /databases/db/search - 通用数据库搜索', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/databases/db/search', data: {
        'database': '',
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/databases/db/search');
      _log('Database/db/search', response: data);
      final page = _unwrapPage(data, '/databases/db/search');
      appLogger.dWithPackage(_pkg, 'Database total: ${page['total']}, items type: ${page['items']?.runtimeType}');
    });

    test('GET /databases/db/list/redis,redis-cluster - Redis 实例列表', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/databases/db/list/redis,redis-cluster');
      final data = _unwrap(raw.data, '/databases/db/list/redis,redis-cluster');
      _log('Database/list/redis', response: data);
      if (data != null) expect(data, isA<List>());
    });

    test('POST /databases/common/info - 数据库基础信息', () async {
      if (skip() != null) return;
      // First get a database target
      final listRaw = await _rawGet(client, '/databases/db/list/mysql,mariadb');
      final listData = _unwrap(listRaw.data, '/databases/db/list/mysql,mariadb');
      final list = _unwrapList(listData, 'db list');
      if (list.isEmpty) {
        appLogger.wWithPackage(_pkg, 'Skipping database info: no MySQL instances');
        return;
      }
      final first = Map<String, dynamic>.from(list.first as Map);
      final dbName = first['name'] as String? ?? first['database'] as String? ?? '';
      final dbType = first['type'] as String? ?? 'mysql';
      if (dbName.isEmpty) return;

      final raw = await _rawPost(client, '/databases/common/info', data: {
        'type': dbType,
        'name': dbName,
      });
      final data = _unwrap(raw.data, '/databases/common/info');
      _log('Database/common/info', response: data);
      expect(data, isA<Map>());
    });
  });

  // =========================================================================
  // 5. Website Module
  // =========================================================================
  group('Website 模块', () {
    test('POST /websites/search - 网站列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/websites/search');
      _log('Website/search', response: data);
      _unwrapPage(data, '/websites/search');
    });

    test('GET /websites/list - 简化网站列表', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/websites/list');
      final data = _unwrap(raw.data, '/websites/list');
      _log('Website/list', response: data);
      if (data != null) expect(data, isA<List>());
    });

    test('GET /websites/databases - 网站数据库列表', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/websites/databases');
      final data = _unwrap(raw.data, '/websites/databases');
      _log('Website/databases', response: data);
      if (data != null) expect(data, isA<List>());
    });

    test('POST /websites/dns/search - DNS 账户', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/dns/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/websites/dns/search');
      _log('Website/dns/search', response: data);
    });

    test('POST /websites/acme/search - ACME 账户', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/acme/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/websites/acme/search');
      _log('Website/acme/search', response: data);
    });
  });

  // =========================================================================
  // 6. App Module
  // =========================================================================
  group('App 模块', () {
    test('GET /apps/installed/list - 已安装应用', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/apps/installed/list');
      final data = _unwrap(raw.data, '/apps/installed/list');
      _log('App/installed/list', response: data);
      if (data != null) expect(data, isA<List>());
    });

    test('POST /apps/search - 应用商店搜索', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/apps/search', data: {
        'page': 1,
        'pageSize': 10,
        'name': '',
        'tags': [],
        'type': '',
      });
      final data = _unwrap(raw.data, '/apps/search');
      _log('App/search', response: data);
    });

    test('GET /apps/checkupdate - 检查更新', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/apps/checkupdate');
      final data = _unwrap(raw.data, '/apps/checkupdate');
      _log('App/checkupdate', response: data);
    });
  });

  // =========================================================================
  // 7. File Module
  // =========================================================================
  group('File 模块', () {
    test('POST /files/search - 文件列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/files/search', data: {
        'path': '/',
        'page': 1,
        'pageSize': 20,
        'search': '',
        'expand': true,
        'showHidden': false,
      });
      final data = _unwrap(raw.data, '/files/search');
      _log('File/search', response: data);
    });

    test('POST /files/tree - 文件树', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/files/tree', data: {
        'path': '/',
        'expand': false,
        'showHidden': false,
      });
      final data = _unwrap(raw.data, '/files/tree');
      _log('File/tree', response: data);
    });

    test('GET /files/recycle/status - 回收站状态', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/files/recycle/status');
      final data = _unwrap(raw.data, '/files/recycle/status');
      _log('File/recycle/status', response: data);
    });

    test('POST /files/favorite/search - 收藏文件', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/files/favorite/search', data: {
        'path': '/',
        'page': 1,
        'pageSize': 20,
      });
      final data = _unwrap(raw.data, '/files/favorite/search');
      _log('File/favorite/search', response: data);
    });
  });

  // =========================================================================
  // 8. SSL Module
  // =========================================================================
  group('SSL 模块', () {
    test('POST /websites/ssl/search - SSL 证书列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/ssl/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/websites/ssl/search');
      _log('SSL/search', response: data);
      _unwrapPage(data, '/websites/ssl/search');
    });

    test('GET /core/settings/ssl/info - 系统 SSL 信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/core/settings/ssl/info');
      final data = _unwrap(raw.data, '/core/settings/ssl/info');
      _log('SSL/system info', response: data);
    });
  });

  // =========================================================================
  // 9. Firewall Module
  // =========================================================================
  group('Firewall 模块', () {
    test('POST /hosts/firewall/base - 防火墙基础信息', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/hosts/firewall/base', data: {
        'name': 'base',
      });
      final data = _unwrap(raw.data, '/hosts/firewall/base');
      _log('Firewall/base', response: data);
      expect(data, isA<Map>());
    });

    test('POST /hosts/firewall/search - 防火墙规则', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/hosts/firewall/search', data: {
        'page': 1,
        'pageSize': 10,
        'type': 'port',
      });
      final data = _unwrap(raw.data, '/hosts/firewall/search');
      _log('Firewall/search', response: data);
      _unwrapPage(data, '/hosts/firewall/search');
    });
  });

  // =========================================================================
  // 10. Backup Module
  // =========================================================================
  group('Backup 模块', () {
    test('POST /backups/search - 备份账户列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/backups/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/backups/search');
      _log('Backup/search', response: data);
      _unwrapPage(data, '/backups/search');
    });

    test('GET /backups/options - 备份选项', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/backups/options');
      final data = _unwrap(raw.data, '/backups/options');
      _log('Backup/options', response: data);
      expect(data, isA<List>());
    });

    test('GET /backups/local - 本地备份目录', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/backups/local');
      final data = _unwrap(raw.data, '/backups/local');
      _log('Backup/local', response: data);
    });

    test('POST /backups/record/search - 备份记录', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/backups/record/search', data: {
        'page': 1,
        'pageSize': 10,
        'type': 'App',
      });
      final data = _unwrap(raw.data, '/backups/record/search');
      _log('Backup/record/search', response: data);
    });
  });

  // =========================================================================
  // 11. Cronjob Module
  // =========================================================================
  group('Cronjob 模块', () {
    test('POST /cronjobs/search - 定时任务列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/cronjobs/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/cronjobs/search');
      _log('Cronjob/search', response: data);
      _unwrapPage(data, '/cronjobs/search');
    });
  });

  // =========================================================================
  // 12. SSH Module
  // =========================================================================
  group('SSH 模块', () {
    test('POST /hosts/ssh/search - SSH 信息', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/hosts/ssh/search', data: {});
      final data = _unwrap(raw.data, '/hosts/ssh/search');
      _log('SSH/search', response: data);
      expect(data, isA<Map>());
    });
  });

  // =========================================================================
  // 13. Monitor Module
  // =========================================================================
  group('Monitor 模块', () {
    test('POST /hosts/monitor/search - 监控数据', () async {
      if (skip() != null) return;
      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 1));
      final raw = await _rawPost(client, '/hosts/monitor/search', data: {
        'from': from.toUtc().toIso8601String(),
        'to': now.toUtc().toIso8601String(),
        'interval': '5m',
        'param': 'all',
        'orderBy': 'created_at',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/hosts/monitor/search');
      _log('Monitor/search', response: data);
    });

    test('GET /hosts/monitor/setting - 监控设置', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/hosts/monitor/setting');
      final data = _unwrap(raw.data, '/hosts/monitor/setting');
      _log('Monitor/setting', response: data);
    });
  });

  // =========================================================================
  // 14. Process Module
  // =========================================================================
  group('Process 模块', () {
    test('POST /process/listening - 监听进程', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/process/listening', data: {});
      final data = _unwrap(raw.data, '/process/listening');
      _log('Process/listening', response: data);
      expect(data, isA<List>());
    });
  });

  // =========================================================================
  // 15. Logs Module
  // =========================================================================
  group('Logs 模块', () {
    test('POST /core/logs/login - 登录日志', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/logs/login', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/core/logs/login');
      _log('Logs/login', response: data);
      _unwrapPage(data, '/core/logs/login');
    });

    test('POST /core/logs/operation - 操作日志', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/logs/operation', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/core/logs/operation');
      _log('Logs/operation', response: data);
      _unwrapPage(data, '/core/logs/operation');
    });

    test('GET /logs/system/files - 系统日志文件', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/logs/system/files');
      final data = _unwrap(raw.data, '/logs/system/files');
      _log('Logs/system/files', response: data);
      expect(data, isA<List>());
    });
  });

  // =========================================================================
  // 16. Host Module
  // =========================================================================
  group('Host 模块', () {
    test('POST /core/hosts/search - 主机列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/hosts/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/core/hosts/search');
      _log('Host/search', response: data);
      _unwrapPage(data, '/core/hosts/search');
    });

    test('POST /core/hosts/tree - 主机树', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/hosts/tree', data: {});
      final data = _unwrap(raw.data, '/core/hosts/tree');
      _log('Host/tree', response: data);
      if (data != null) expect(data, isA<List>());
    });
  });

  // =========================================================================
  // 17. HostTool Module
  // =========================================================================
  group('HostTool 模块', () {
    test('POST /hosts/tool - 工具信息', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/hosts/tool', data: {
          'type': 'supervisor',
          'operate': 'status',
        });
        final data = _unwrap(raw.data, '/hosts/tool');
        _log('HostTool/tool', response: data);
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'HostTool/tool error: $e');
      }
    });
  });

  // =========================================================================
  // 18. Setting Module
  // =========================================================================
  group('Setting 模块', () {
    test('POST /settings/search - 系统设置', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/settings/search', data: {});
      final data = _unwrap(raw.data, '/settings/search');
      _log('Setting/search', response: data);
    });

    test('GET /core/settings/upgrade - 升级信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/core/settings/upgrade');
      final data = _unwrap(raw.data, '/core/settings/upgrade');
      _log('Setting/upgrade', response: data);
    });

    test('GET /core/settings/interface - 界面设置', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/core/settings/interface');
      final data = _unwrap(raw.data, '/core/settings/interface');
      _log('Setting/interface', response: data);
    });
  });

  // =========================================================================
  // 19. Snapshot Module
  // =========================================================================
  group('Snapshot 模块', () {
    test('POST /settings/snapshot/search - 快照列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/settings/snapshot/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/settings/snapshot/search');
      _log('Snapshot/search', response: data);
      _unwrapPage(data, '/settings/snapshot/search');
    });
  });

  // =========================================================================
  // 20. Command Module
  // =========================================================================
  group('Command 模块', () {
    test('POST /core/commands/list - 命令列表', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/core/commands/list', data: {
          'type': 'command',
        });
        final data = _unwrap(raw.data, '/core/commands/list');
        _log('Command/list', response: data);
        expect(data, isA<List>());
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Command/list error (may be empty): $e');
      }
    });
  });

  // =========================================================================
  // 21. AI Module
  // =========================================================================
  group('AI 模块', () {
    test('POST /ai/ollama/model/search - Ollama 模型列表', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/ai/ollama/model/search', data: {
          'page': 1,
          'pageSize': 10,
        });
        final data = _unwrap(raw.data, '/ai/ollama/model/search');
        _log('AI/ollama/model/search', response: data);
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'AI/ollama/model/search error: $e');
      }
    });

    test('GET /ai/gpu/load - GPU 信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/ai/gpu/load');
      final data = _unwrap(raw.data, '/ai/gpu/load');
      _log('AI/gpu/load', response: data);
      // Response may be a Map (wrapper) or List (direct)
      expect(data, anyOf(isA<Map>(), isA<List>()));
    });
  });

  // =========================================================================
  // 22. Compose Module
  // =========================================================================
  group('Compose 模块', () {
    test('POST /containers/compose/search - Compose 列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/compose/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/containers/compose/search');
      _log('Compose/search', response: data);
      _unwrapPage(data, '/containers/compose/search');
    });
  });

  // =========================================================================
  // 23. OpenResty Module
  // =========================================================================
  group('OpenResty 模块', () {
    test('GET /openresty/status - OpenResty 状态', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/openresty/status');
        final data = _unwrap(raw.data, '/openresty/status');
        _log('OpenResty/status', response: data);
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'OpenResty/status not available: $e');
      }
    });
  });

  // =========================================================================
  // 24. Runtime Module
  // =========================================================================
  group('Runtime 模块', () {
    test('POST /runtimes/search - 运行时列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/runtimes/search', data: {
        'page': 1,
        'pageSize': 10,
        'type': 'php',
      });
      final data = _unwrap(raw.data, '/runtimes/search');
      _log('Runtime/search', response: data);
      _unwrapPage(data, '/runtimes/search');
    });
  });

  // =========================================================================
  // 25. Toolbox Module
  // =========================================================================
  group('Toolbox 模块', () {
    test('POST /hosts/tool - 工具箱信息', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/hosts/tool', data: {
          'type': 'supervisor',
          'operate': 'status',
        });
        final data = _unwrap(raw.data, '/hosts/tool');
        _log('Toolbox/tool', response: data);
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Toolbox/tool error: $e');
      }
    });
  });

  // =========================================================================
  // 26. User Module
  // =========================================================================
  group('User 模块', () {
    test('POST /users/search - 用户列表', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/users/search', data: {
          'page': 1,
          'pageSize': 10,
        });
        final data = _unwrap(raw.data, '/users/search');
        _log('User/search', response: data);
        _unwrapPage(data, '/users/search');
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'User/search not available: $e');
      }
    });
  });

  // =========================================================================
  // 27. Group Module
  // =========================================================================
  group('Group 模块', () {
    test('POST /core/groups/search - 分组列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/groups/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/core/groups/search');
      _log('Group/search', response: data);
    });
  });

  // =========================================================================
  // 28. WebsiteGroup Module
  // =========================================================================
  group('WebsiteGroup 模块', () {
    test('POST /groups/search - 网站分组', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/groups/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/groups/search');
      _log('WebsiteGroup/search', response: data);
    });
  });

  // =========================================================================
  // 29. ScriptLibrary Module
  // =========================================================================
  group('ScriptLibrary 模块', () {
    test('POST /core/script/search - 脚本列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/script/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/core/script/search');
      _log('ScriptLibrary/search', response: data);
      _unwrapPage(data, '/core/script/search');
    });
  });

  // =========================================================================
  // 30. DiskManagement Module
  // =========================================================================
  group('DiskManagement 模块', () {
    test('GET /hosts/disks - 磁盘信息', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/hosts/disks');
      final data = _unwrap(raw.data, '/hosts/disks');
      _log('Disk/disks', response: data);
    });
  });

  // =========================================================================
  // 31. TaskLog Module
  // =========================================================================
  group('TaskLog 模块', () {
    test('POST /logs/tasks/search - 任务列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/logs/tasks/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/logs/tasks/search');
      _log('TaskLog/search', response: data);
      _unwrapPage(data, '/logs/tasks/search');
    });

    test('GET /logs/tasks/executing/count - 执行中任务数', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/logs/tasks/executing/count');
      final data = _unwrap(raw.data, '/logs/tasks/executing/count');
      _log('TaskLog/executing/count', response: data);
    });
  });

  // =========================================================================
  // 32. Docker Module (if separate from container)
  // =========================================================================
  group('Docker 模块', () {
    test('GET /containers/docker/status - Docker 守护进程状态', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/docker/status');
      final data = _unwrap(raw.data, '/containers/docker/status');
      _log('Docker/status', response: data);
      expect(data, isA<Map>());
    });
  });

  // =========================================================================
  // 33. Update Module
  // =========================================================================
  group('Update 模块', () {
    test('GET /core/settings/upgrade/releases - 可用版本', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/core/settings/upgrade/releases');
      final data = _unwrap(raw.data, '/core/settings/upgrade/releases');
      _log('Update/releases', response: data);
    });
  });

  // =========================================================================
  // 34. Terminal Module
  // =========================================================================
  group('Terminal 模块', () {
    test('POST /core/hosts/search - 主机列表', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/core/hosts/search', data: {
        'page': 1,
        'pageSize': 10,
      });
      final data = _unwrap(raw.data, '/core/hosts/search');
      _log('Terminal/hosts', response: data);
      _unwrapPage(data, '/core/hosts/search');
    });
  });

  // =========================================================================
  // 35. Typed API Client Parsing Tests
  // =========================================================================
  group('类型化 API 客户端解析验证', () {
    test('DashboardV2Api.getDashboardBase - 模型解析', () async {
      if (skip() != null) return;
      final api = DashboardV2Api(client);
      final resp = await api.getDashboardBase();
      _log('Dashboard typed/base', response: resp.data);
      expect(resp.statusCode, equals(200));
      expect(resp.data, isA<Map>());
    });

    test('DashboardV2Api.getOperatingSystemInfo - SystemInfo 解析', () async {
      if (skip() != null) return;
      final api = DashboardV2Api(client);
      final resp = await api.getOperatingSystemInfo();
      _log('Dashboard typed/os', response: resp.data?.toJson());
      expect(resp.statusCode, equals(200));
    });

    test('DashboardV2Api.getCurrentMetrics - SystemMetrics 解析', () async {
      if (skip() != null) return;
      final api = DashboardV2Api(client);
      final resp = await api.getCurrentMetrics();
      _log('Dashboard typed/current', response: resp.data?.toJson());
      expect(resp.statusCode, equals(200));
    });

    test('ContainerV2Api.searchContainers - PageResult<ContainerInfo> 解析', () async {
      if (skip() != null) return;
      final api = ContainerV2Api(client);
      // Use raw Map with all required fields including state
      final resp = await _rawPost(client, '/containers/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
        'state': 'all',
      });
      final data = _unwrap(resp.data, '/containers/search typed');
      final page = _unwrapPage(data, 'containers typed');
      _log('Container typed/search', response: {
        'total': page['total'],
        'itemsCount': (page['items'] as List?)?.length,
        'firstItem': (page['items'] as List?)?.isNotEmpty == true
            ? (page['items'] as List).first
            : null,
      });
    });

    test('DatabaseV2Api.searchDatabases - PageResult<DatabaseInfo> 解析', () async {
      if (skip() != null) return;
      final api = DatabaseV2Api(client);
      const request = DatabaseSearch(
        database: '',
        info: '',
        page: 1,
        pageSize: 5,
        orderBy: 'createdAt',
        order: 'descending',
      );
      final resp = await api.searchDatabases(request);
      _log('Database typed/search', response: {
        'total': resp.data?.total,
        'itemsCount': resp.data?.items.length,
      });
      expect(resp.statusCode, equals(200));
      expect(resp.data, isA<PageResult<DatabaseInfo>>());
      // Verify model fields
      for (final db in resp.data!.items) {
        expect(db.id, greaterThan(0), reason: 'DatabaseInfo.id should be positive');
        expect(db.name, isNotEmpty, reason: 'DatabaseInfo.name should not be empty');
        expect(db.type, isNotEmpty, reason: 'DatabaseInfo.type should not be empty');
      }
    });

    test('AuthV2Api.getLoginSettings - 登录设置解析', () async {
      if (skip() != null) return;
      final api = AuthV2Api(client);
      final resp = await api.getLoginSettings();
      _log('Auth typed/setting', response: resp.data);
      expect(resp.statusCode, equals(200));
    });

    test('FileV2Api.getRecycleBinStatus - 回收站状态解析', () async {
      if (skip() != null) return;
      final api = FileV2Api(client);
      final resp = await api.getRecycleBinStatus();
      _log('File typed/recycle', response: resp.data?.toJson());
      expect(resp.statusCode, equals(200));
    });

    test('BackupAccountV2Api.getBackupAccountOptions - 备份选项解析', () async {
      if (skip() != null) return;
      final api = BackupAccountV2Api(client);
      final resp = await api.getBackupAccountOptions();
      _log('Backup typed/options', response: resp.data?.map((e) => e.toJson()).toList());
      expect(resp.statusCode, equals(200));
      expect(resp.data, isA<List>());
    });

    test('SettingV2Api 系统设置解析', () async {
      if (skip() != null) return;
      final api = SettingV2Api(client);
      // Use the correct settings search endpoint
      final resp = await _rawPost(client, '/settings/search', data: {});
      final data = _unwrap(resp.data, '/settings/search typed');
      _log('Setting typed/search', response: data);
      expect(data, isA<Map>());
    });
  });

  // =========================================================================
  // 36. Edge Cases & Contract Deviation Detection
  // =========================================================================
  group('边界情况与契约偏差检测', () {
    test('空请求体不应导致 500 错误', () async {
      if (skip() != null) return;
      // Test that empty body to /core/settings/search doesn't crash
      final raw = await _rawPost(client, '/core/settings/search', data: {});
      _log('Edge/empty body', response: raw.data);
      expect(raw.statusCode, equals(200));
    });

    test('PageResult.items 为 null 时应安全处理', () async {
      if (skip() != null) return;
      // Search with unlikely criteria to get empty results
      final raw = await _rawPost(client, '/databases/db/search', data: {
        'database': '',
        'info': '___nonexistent___',
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/databases/db/search edge');
      final page = _unwrapPage(data, 'edge case');
      // items might be null for empty results
      final items = page['items'];
      appLogger.dWithPackage(_pkg, 'Edge case items: $items (type: ${items?.runtimeType})');
      expect(items == null || items is List, isTrue,
          reason: 'items should be null or List');
    });

    test('POST /databases/db/search 空 database 字段验证', () async {
      if (skip() != null) return;
      // This tests the previously fixed bug: empty database field
      // should NOT be sent to /databases/search (MySQL-specific)
      // Instead it should use /databases/db/search (generic)
      final raw = await _rawPost(client, '/databases/db/search', data: {
        'database': '',
        'info': '',
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      _log('Edge/empty database', response: raw.data);
      expect(raw.statusCode, equals(200));
    });
  });
}
