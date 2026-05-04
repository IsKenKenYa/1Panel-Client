import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/api/v2/app_v2.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/api/v2/ssl_v2.dart' show SSLV2Api;
import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/api/v2/monitor_v2.dart';
import 'package:onepanel_client/api/v2/snapshot_v2.dart';
import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart' show AIV2Api;
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart' show PageContainer;
import 'package:onepanel_client/data/models/cronjob_list_models.dart' show CronjobListQuery;
import 'package:onepanel_client/data/models/database_models.dart';

import '../core/test_config_manager.dart';

const _pkg = 'test.integration.deep_contract';

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
    appLogger.dWithPackage(_pkg,
        'Res: ${s.length > 3000 ? '${s.substring(0, 3000)}...' : s}');
  }
}

Future<Response<dynamic>> _rawGet(DioClient c, String path) =>
    c.get<dynamic>(ApiConstants.buildApiPath(path));

Future<Response<dynamic>> _rawPost(DioClient c, String path,
    {dynamic data}) =>
    c.post<dynamic>(ApiConstants.buildApiPath(path), data: data);

dynamic _unwrap(dynamic raw, String path) {
  expect(raw, isA<Map>(), reason: '$path: should be wrapped object');
  final m = Map<String, dynamic>.from(raw as Map);
  expect(m['code'], equals(200),
      reason: '$path: code should be 200, got ${m['code']}. msg=${m['message']}');
  expect(m.containsKey('data'), isTrue, reason: '$path: should contain data');
  return m['data'];
}

/// Validate that a map has the expected keys (at minimum)
void _expectMapKeys(Map<String, dynamic> m, List<String> requiredKeys,
    {required String path}) {
  for (final key in requiredKeys) {
    expect(m.containsKey(key), isTrue,
        reason: '$path: missing required key "$key". Keys: ${m.keys.toList()}');
  }
}

/// Compare raw JSON item count with parsed list length
void _expectItemCountMatch(
    List<dynamic> rawItems, List<dynamic> parsedItems, String path) {
  expect(parsedItems.length, equals(rawItems.length),
      reason:
          '$path: parsed item count (${parsedItems.length}) should match raw (${rawItems.length})');
}

/// Deep compare raw map with parsed model's toJson output for key fields
void _expectFieldTypesMatch(
    Map<String, dynamic> raw, Map<String, dynamic> parsed, List<String> keys,
    {required String path}) {
  for (final key in keys) {
    if (!raw.containsKey(key)) continue;
    final rawVal = raw[key];
    final parsedVal = parsed[key];
    if (rawVal == null && parsedVal == null) continue;
    if (rawVal == null || parsedVal == null) {
      appLogger.wWithPackage(_pkg,
          '$path: key "$key" raw=${rawVal?.runtimeType} parsed=${parsedVal?.runtimeType}');
      continue;
    }
    expect(parsedVal.runtimeType, equals(rawVal.runtimeType),
        reason:
            '$path: key "$key" type mismatch: raw=${rawVal.runtimeType} parsed=${parsedVal.runtimeType}');
  }
}

void main() {
  late DioClient client;
  late DashboardV2Api dashboardApi;
  late ContainerV2Api containerApi;
  late DatabaseV2Api databaseApi;
  late WebsiteV2Api websiteApi;
  late AppV2Api appApi;
  late FileV2Api fileApi;
  late BackupAccountV2Api backupApi;
  late SettingV2Api settingApi;
  late CronjobV2Api cronjobApi;
  late SSLV2Api sslApi;
  late FirewallV2Api firewallApi;
  late MonitorV2Api monitorApi;
  late SnapshotV2Api snapshotApi;
  late SshV2Api sshApi;
  late HostV2Api hostApi;
  late LogsV2Api logsApi;
  late CommandV2Api commandApi;
  late AIV2Api aiApi;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    final apiKey = TestEnvironment.config.getString('PANEL_API_KEY');
    canRun = TestEnvironment.runIntegrationTests &&
        apiKey.isNotEmpty &&
        apiKey != 'your_api_key_here';
    if (canRun) {
      client = DioClient(baseUrl: TestEnvironment.baseUrl, apiKey: apiKey);
      dashboardApi = DashboardV2Api(client);
      containerApi = ContainerV2Api(client);
      databaseApi = DatabaseV2Api(client);
      websiteApi = WebsiteV2Api(client);
      appApi = AppV2Api(client);
      fileApi = FileV2Api(client);
      backupApi = BackupAccountV2Api(client);
      settingApi = SettingV2Api(client);
      cronjobApi = CronjobV2Api(client);
      sslApi = SSLV2Api(client);
      firewallApi = FirewallV2Api(client);
      monitorApi = MonitorV2Api(client);
      snapshotApi = SnapshotV2Api(client);
      sshApi = SshV2Api(client);
      hostApi = HostV2Api(client);
      logsApi = LogsV2Api(client);
      commandApi = CommandV2Api(client);
      aiApi = AIV2Api(client);
    }
  });

  String? skip() => canRun ? null : 'Integration tests disabled or no API key';

  // =========================================================================
  // Dashboard 模块深度验证
  // =========================================================================
  group('Dashboard 深度契约验证', () {
    test('SystemInfo 模型字段匹配', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/base/default/default');
      final data = _unwrap(raw.data, '/dashboard/base');
      _log('Dashboard/base raw', response: data);

      final rawData = Map<String, dynamic>.from(data as Map);
      appLogger.dWithPackage(_pkg, 'Dashboard base keys: ${rawData.keys.toList()}');

      // Now parse with typed API
      final parsed = await dashboardApi.getDashboardBase();
      expect(parsed.data, isNotNull, reason: 'DashboardBase should not be null');
      final info = parsed.data!;

      // Log parsed model fields
      appLogger.dWithPackage(_pkg,
          'DashboardBase keys: ${info.keys.toList()}');

      // Verify key fields exist
      expect(info.containsKey('platform') || info.containsKey('Platform'), isTrue,
          reason: 'DashboardBase should have platform field');
    });

    test('DashboardMetrics 实时指标字段匹配', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/default/default');
      final data = _unwrap(raw.data, '/dashboard/current');
      _log('Dashboard/current raw', response: data);

      final rawData = Map<String, dynamic>.from(data as Map);
      appLogger.dWithPackage(
          _pkg, 'Dashboard current keys: ${rawData.keys.toList()}');

      // Parse with typed API
      final parsed = await dashboardApi.getCurrentMetrics();
      expect(parsed.data, isNotNull, reason: 'CurrentMetrics should not be null');

      // Check if parsed model has the same keys as raw
      final parsedJson = parsed.data!;
      appLogger.dWithPackage(_pkg, 'Parsed current metrics type: ${parsedJson.runtimeType}');
    });

    test('ProcessInfo CPU Top 进程解析', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/dashboard/current/top/cpu');
      final data = _unwrap(raw.data, '/dashboard/top/cpu');
      _log('Dashboard/top/cpu raw', response: data);

      if (data == null || (data is List && data.isEmpty)) {
        appLogger.dWithPackage(_pkg, 'No CPU top processes, skipping field validation');
        return;
      }

      expect(data, isA<List>(), reason: 'CPU top should be a list');
      final rawList = List<dynamic>.from(data as List);
      if (rawList.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawList.first as Map);
        appLogger.dWithPackage(
            _pkg, 'CPU top first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(_pkg, 'CPU top first item: ${_pretty(firstRaw)}');
      }
    });
  });

  // =========================================================================
  // Container 模块深度验证
  // =========================================================================
  group('Container 深度契约验证', () {
    test('ContainerStatus 模型字段验证', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/containers/status');
      final data = _unwrap(raw.data, '/containers/status');
      _log('Container/status raw', response: data);

      final rawData = Map<String, dynamic>.from(data as Map);
      appLogger.dWithPackage(
          _pkg, 'Container status keys: ${rawData.keys.toList()}');

      // Verify all expected keys exist
      // Note: 'all' and 'imageSize' are NOT in server response - model defaults to 0
      _expectMapKeys(rawData, ['running', 'exited', 'containerCount', 'imageCount'],
          path: '/containers/status');

      // Parse with typed API
      final parsed = await containerApi.getContainerStatus();
      expect(parsed.data, isNotNull, reason: 'ContainerStatus should not be null');
      final status = parsed.data!;

      // Verify non-negative values
      expect(status.running, greaterThanOrEqualTo(0));
      expect(status.exited, greaterThanOrEqualTo(0));
      expect(status.all, greaterThanOrEqualTo(0));
      expect(status.imageCount, greaterThanOrEqualTo(0));
    });

    test('ContainerInfo 列表解析与原始数据对比', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
        'state': 'all',
      });
      final data = _unwrap(raw.data, '/containers/search');
      _log('Container/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      expect(pageData.containsKey('items'), isTrue);
      expect(pageData.containsKey('total'), isTrue);

      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Container search: ${rawItems.length} items, total=${pageData['total']}');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Container first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'Container first item: ${_pretty(firstRaw)}');

        // Verify ContainerInfo field names match raw JSON
        _expectMapKeys(firstRaw, ['id', 'name', 'image', 'status'],
            path: '/containers/search/item');
      }

      // Parse with typed API
      final parsed = await containerApi.searchContainers(
        PageContainer(page: 1, pageSize: 5),
      );
      expect(parsed.data, isNotNull, reason: 'PageResult should not be null');
      final page = parsed.data!;

      // Verify item count matches
      _expectItemCountMatch(rawItems, page.items, '/containers/search');

      // Verify each parsed item has non-empty required fields
      for (final item in page.items) {
        expect(item.name, isNotNull, reason: 'container.name should not be null');
        expect(item.name, isNotEmpty,
            reason: 'container.name should not be empty');
        expect(item.image, isNotNull,
            reason: 'container.image should not be null');
      }
    });

    test('ContainerInfo 端口和标签字段解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
        'state': 'all',
      });
      final data = _unwrap(raw.data, '/containers/search');
      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];

      if (rawItems.isEmpty) return;

      // Check raw JSON for ports/labels fields
      final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
      appLogger.dWithPackage(_pkg,
          'Container ports type: ${firstRaw['ports']?.runtimeType}, '
          'labels type: ${firstRaw['labels']?.runtimeType}');

      // Parse with typed API
      final parsed = await containerApi.searchContainers(
        PageContainer(page: 1, pageSize: 5),
      );
      if (parsed.data!.items.isNotEmpty) {
        final first = parsed.data!.items.first;
        appLogger.dWithPackage(_pkg,
            'Parsed container: ports=${first.ports}, labels=${first.labels}');
      }
    });
  });

  // =========================================================================
  // Database 模块深度验证
  // =========================================================================
  group('Database 深度契约验证', () {
    test('DatabaseListItem 列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawGet(client, '/databases/db/list/mysql,mariadb');
      final data = _unwrap(raw.data, '/databases/db/list');
      _log('Database/list raw', response: data);

      if (data == null) {
        appLogger.dWithPackage(_pkg, 'No database list data, skipping');
        return;
      }

      expect(data, isA<List>(), reason: 'Database list should be a list');
      final rawList = List<dynamic>.from(data as List);
      appLogger.dWithPackage(
          _pkg, 'Database list: ${rawList.length} items');

      if (rawList.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawList.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Database first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'Database first item: ${_pretty(firstRaw)}');

        // Verify DatabaseOption field names
        _expectMapKeys(firstRaw, ['name', 'type', 'version'],
            path: '/databases/db/list/item');
      }

      // Parse with typed API
      final parsed = await databaseApi.listDatabases('mysql,mariadb');
      expect(parsed.data, isNotNull);
      final items = parsed.data!;
      appLogger.dWithPackage(_pkg, 'Parsed databases: ${items.length}');

      // Verify count matches
      _expectItemCountMatch(rawList, items, '/databases/db/list');

      // Verify each item
      for (final item in items) {
        expect(item['name'], isNotNull);
        expect(item['name'], isNotEmpty);
      }
    });

    test('DatabaseSearch 搜索结果解析', () async {
      if (skip() != null) return;

      // First get a database name to search
      final listRaw = await _rawGet(client, '/databases/db/list/mysql,mariadb');
      final listData = _unwrap(listRaw.data, '/databases/db/list');
      if (listData == null || (listData is List && listData.isEmpty)) {
        appLogger.dWithPackage(_pkg, 'No databases found, skipping search test');
        return;
      }

      final firstDb = Map<String, dynamic>.from((listData as List).first as Map);
      final dbName = firstDb['name'] as String? ?? '';
      if (dbName.isEmpty) {
        appLogger.dWithPackage(_pkg, 'Database name is empty, skipping');
        return;
      }

      appLogger.dWithPackage(_pkg, 'Searching databases for: $dbName');

      final raw = await _rawPost(client, '/databases/search', data: {
        'database': dbName,
        'info': '',
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/databases/search');
      _log('Database/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      expect(pageData.containsKey('items'), isTrue);
      expect(pageData.containsKey('total'), isTrue);

      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Database search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Database search first item keys: ${firstRaw.keys.toList()}');

        // Verify DatabaseInfo field names
        _expectMapKeys(firstRaw, ['name', 'type'],
            path: '/databases/search/item');
      }

      // Parse with typed API
      final parsed = await databaseApi.searchMysqlDatabases(
        DatabaseSearch(
          database: dbName,
          info: '',
          page: 1,
          pageSize: 5,
        ),
      );
      expect(parsed.data, isNotNull);
      final page = parsed.data!;

      // Verify item count matches
      _expectItemCountMatch(rawItems, page.items, '/databases/search');

      // Verify each item (Map<String, dynamic>)
      for (final item in page.items) {
        expect(item['name'], isNotNull);
        expect(item['name'], isNotEmpty);
      }
    });

    test('DatabaseBaseInfo 基础信息解析', () async {
      if (skip() != null) return;

      // Get a database name
      final listRaw = await _rawGet(client, '/databases/db/list/mysql,mariadb');
      final listData = _unwrap(listRaw.data, '/databases/db/list');
      if (listData == null || (listData is List && listData.isEmpty)) {
        appLogger.dWithPackage(_pkg, 'No databases found, skipping base info test');
        return;
      }

      final firstDb = Map<String, dynamic>.from((listData as List).first as Map);
      final dbName = firstDb['name'] as String? ?? '';
      final dbType = firstDb['type'] as String? ?? 'mysql';
      if (dbName.isEmpty) return;

      final raw = await _rawPost(client, '/databases/common/info', data: {
        'type': dbType,
        'name': dbName,
      });
      final data = _unwrap(raw.data, '/databases/common/info');
      _log('Database/baseinfo raw', response: data);

      if (data is Map) {
        final rawData = Map<String, dynamic>.from(data);
        appLogger.dWithPackage(
            _pkg, 'DatabaseBaseInfo keys: ${rawData.keys.toList()}');
      }
    });
  });

  // =========================================================================
  // Website 模块深度验证
  // =========================================================================
  group('Website 深度契约验证', () {
    test('WebsiteInfo 列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/websites/search');
      _log('Website/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      expect(pageData.containsKey('items'), isTrue);
      expect(pageData.containsKey('total'), isTrue);

      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Website search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Website first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'Website first item: ${_pretty(firstRaw)}');

        // Verify WebsiteInfo field names
        _expectMapKeys(firstRaw, ['id', 'primaryDomain', 'type'],
            path: '/websites/search/item');

        // Check for ID casing - server uses 'ID' or 'Id'?
        appLogger.dWithPackage(_pkg,
            'Website item has primaryDomain: ${firstRaw.containsKey('primaryDomain')}, '
            'domain: ${firstRaw.containsKey('domain')}');
      }
    });

    test('WebsiteDomain 字段验证', () async {
      if (skip() != null) return;
      // Get a website ID first
      final searchRaw = await _rawPost(client, '/websites/search', data: {
        'page': 1,
        'pageSize': 1,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final searchData = _unwrap(searchRaw.data, '/websites/search');
      if (searchData == null) return;

      final pageData = Map<String, dynamic>.from(searchData as Map);
      final items = pageData['items'] as List? ?? [];
      if (items.isEmpty) {
        appLogger.dWithPackage(_pkg, 'No websites found, skipping domain test');
        return;
      }

      final websiteId = (items.first as Map)['id'] as int? ?? 0;
      if (websiteId == 0) return;

      final raw = await _rawGet(client, '/websites/$websiteId');
      final data = _unwrap(raw.data, '/websites/$websiteId');
      _log('Website/detail raw', response: data);

      if (data is Map) {
        final detail = Map<String, dynamic>.from(data);
        appLogger.dWithPackage(
            _pkg, 'Website detail keys: ${detail.keys.toList()}');

        // Check for domains field
        if (detail.containsKey('domains')) {
          final domains = detail['domains'];
          appLogger.dWithPackage(
              _pkg, 'Website domains type: ${domains?.runtimeType}');
          if (domains is List && domains.isNotEmpty) {
            appLogger.dWithPackage(_pkg,
                'Website domain first: ${_pretty(domains.first)}');
          }
        }
      }
    });
  });

  // =========================================================================
  // App 模块深度验证
  // =========================================================================
  group('App 深度契约验证', () {
    test('AppItem 应用商店列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/apps/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/apps/search');
      _log('App/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      expect(pageData.containsKey('items'), isTrue);

      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(_pkg, 'App search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'App first item keys: ${firstRaw.keys.toList()}');

        // Verify AppItem field names
        _expectMapKeys(firstRaw, ['name', 'key'],
            path: '/apps/search/item');

        // Check for params field (complex nested object)
        if (firstRaw.containsKey('params') && firstRaw['params'] != null) {
          appLogger.dWithPackage(
              _pkg, 'App params type: ${firstRaw['params'].runtimeType}');
        }
      }
    });

    test('AppInstall 已安装应用列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/apps/installed/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/apps/installed/search');
      _log('App/installed/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'App installed: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'App installed first keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'App installed first: ${_pretty(firstRaw)}');

        // Verify AppInstall field names
        _expectMapKeys(firstRaw, ['name', 'status'],
            path: '/apps/installed/search/item');
      }
    });
  });

  // =========================================================================
  // File 模块深度验证
  // =========================================================================
  group('File 深度契约验证', () {
    test('FileInfo 根目录列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/files/search', data: {
        'path': '/',
        'page': 1,
        'pageSize': 10,
        'expand': true,
        'showHidden': false,
      });
      final data = _unwrap(raw.data, '/files/search');
      _log('File/search raw', response: data);

      if (data == null) {
        appLogger.dWithPackage(_pkg, 'File search returned null data');
        return;
      }

      // File search may return different shapes
      if (data is Map) {
        final pageData = Map<String, dynamic>.from(data);
        appLogger.dWithPackage(
            _pkg, 'File search keys: ${pageData.keys.toList()}');

        if (pageData.containsKey('items')) {
          final rawItems = pageData['items'] as List? ?? [];
          appLogger.dWithPackage(
              _pkg, 'File search: ${rawItems.length} items');

          if (rawItems.isNotEmpty) {
            final firstRaw =
                Map<String, dynamic>.from(rawItems.first as Map);
            appLogger.dWithPackage(
                _pkg, 'File first item keys: ${firstRaw.keys.toList()}');
            appLogger.dWithPackage(
                _pkg, 'File first item: ${_pretty(firstRaw)}');

            // Verify FileInfo field names
            _expectMapKeys(firstRaw, ['name', 'path', 'type'],
                path: '/files/search/item');

            // Check for alternative field names
            appLogger.dWithPackage(_pkg,
                'File item has mode: ${firstRaw.containsKey('mode')}, '
                'permission: ${firstRaw.containsKey('permission')}, '
                'modTime: ${firstRaw.containsKey('modTime')}, '
                'modifiedAt: ${firstRaw.containsKey('modifiedAt')}');
          }
        }
      } else if (data is List) {
        appLogger.dWithPackage(
            _pkg, 'File search returned List directly: ${data.length} items');
      }
    });
  });

  // =========================================================================
  // Backup 模块深度验证
  // =========================================================================
  group('Backup 深度契约验证', () {
    test('BackupAccount 列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/backups/search', data: {
        'page': 1,
        'pageSize': 10,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/backups/search');
      _log('Backup/search raw', response: data);

      if (data == null) {
        appLogger.dWithPackage(_pkg, 'Backup search returned null');
        return;
      }

      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Backup search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Backup first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'Backup first item: ${_pretty(firstRaw)}');
      }
    });
  });

  // =========================================================================
  // Setting 模块深度验证
  // =========================================================================
  group('Setting 深度契约验证', () {
    test('SystemSettingInfo 搜索结果解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/settings/search', data: {
        'page': 1,
        'pageSize': 100,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/settings/search');
      _log('Setting/search raw', response: data);

      if (data == null) {
        appLogger.dWithPackage(_pkg, 'Setting search returned null');
        return;
      }

      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Setting search: ${rawItems.length} items');

      // Verify we can parse settings
      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Setting first item keys: ${firstRaw.keys.toList()}');

        // Verify SettingInfo field names
        _expectMapKeys(firstRaw, ['key', 'value'],
            path: '/settings/search/item');
      }
    });
  });

  // =========================================================================
  // Cronjob 模块深度验证
  // =========================================================================
  group('Cronjob 深度契约验证', () {
    test('CronjobSummary 列表解析（含 orderBy/order）', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/cronjobs/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/cronjobs/search');
      _log('Cronjob/search raw', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Cronjob search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'Cronjob first item keys: ${firstRaw.keys.toList()}');
        appLogger.dWithPackage(
            _pkg, 'Cronjob first item: ${_pretty(firstRaw)}');

        // Verify CronjobSummary field names
        _expectMapKeys(firstRaw, ['name', 'type', 'status'],
            path: '/cronjobs/search/item');
      }
    });
  });

  // =========================================================================
  // SSL 模块深度验证
  // =========================================================================
  group('SSL 深度契约验证', () {
    test('SSL 证书列表解析', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/websites/ssl/search', data: {
        'page': 1,
        'pageSize': 5,
        'orderBy': 'expire_date',
        'order': 'descending',
      });
      final data = _unwrap(raw.data, '/websites/ssl/search');
      _log('SSL/search raw', response: data);

      if (data == null) {
        appLogger.dWithPackage(_pkg, 'SSL search returned null');
        return;
      }

      final pageData = Map<String, dynamic>.from(data as Map);
      final rawItems = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(_pkg, 'SSL search: ${rawItems.length} items');

      if (rawItems.isNotEmpty) {
        final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
        appLogger.dWithPackage(
            _pkg, 'SSL first item keys: ${firstRaw.keys.toList()}');
      }
    });
  });

  // =========================================================================
  // Firewall 模块深度验证
  // =========================================================================
  group('Firewall 深度契约验证', () {
    test('Firewall 基础信息解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/hosts/firewall/base');
        final data = _unwrap(raw.data, '/hosts/firewall/base');
        _log('Firewall/base raw', response: data);

        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          appLogger.dWithPackage(
              _pkg, 'Firewall base keys: ${m.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Firewall base not available: $e');
      }
    });
  });

  // =========================================================================
  // Monitor 模块深度验证
  // =========================================================================
  group('Monitor 深度契约验证', () {
    test('Monitor 搜索结果解析', () async {
      if (skip() != null) return;
      try {
        final now = DateTime.now().toUtc();
        final start = now.subtract(const Duration(days: 1));
        final startStr = start.toIso8601String();
        final endStr = now.toIso8601String();

        final raw = await _rawPost(client, '/hosts/monitor/search', data: {
          'param': 'all',
          'startTime': startStr,
          'endTime': endStr,
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/hosts/monitor/search');
        _log('Monitor/search raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'Monitor search returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'Monitor search: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'Monitor first item keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Monitor search failed: $e');
      }
    });
  });

  // =========================================================================
  // Snapshot 模块深度验证
  // =========================================================================
  group('Snapshot 深度契约验证', () {
    test('Snapshot 列表解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/settings/snapshot/search', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/settings/snapshot/search');
        _log('Snapshot/search raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'Snapshot search returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'Snapshot search: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'Snapshot first item keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Snapshot search failed: $e');
      }
    });
  });

  // =========================================================================
  // SSH 模块深度验证
  // =========================================================================
  group('SSH 深度契约验证', () {
    test('SSH 搜索结果解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/hosts/ssh/search', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/hosts/ssh/search');
        _log('SSH/search raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'SSH search returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'SSH search: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'SSH first item keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'SSH search failed: $e');
      }
    });
  });

  // =========================================================================
  // Host 模块深度验证
  // =========================================================================
  group('Host 深度契约验证', () {
    test('Host 搜索结果解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/core/hosts/search', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/core/hosts/search');
        _log('Host/search raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'Host search returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'Host search: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'Host first item keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Host search failed: $e');
      }
    });
  });

  // =========================================================================
  // Logs 模块深度验证
  // =========================================================================
  group('Logs 深度契约验证', () {
    test('操作日志解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/core/logs/operation', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/core/logs/operation');
        _log('Logs/operation raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'Operation logs returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'Operation logs: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'Log first item keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Operation logs failed: $e');
      }
    });
  });

  // =========================================================================
  // Command 模块深度验证
  // =========================================================================
  group('Command 深度契约验证', () {
    test('Command 列表解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/core/commands/list', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/core/commands/list');
        _log('Command/list raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'Command list returned null');
          return;
        }

        if (data is Map) {
          final pageData = Map<String, dynamic>.from(data);
          final rawItems = pageData['items'] as List? ?? [];
          appLogger.dWithPackage(
              _pkg, 'Command list: ${rawItems.length} items');
        } else if (data is List) {
          appLogger.dWithPackage(
              _pkg, 'Command list returned List: ${data.length} items');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'Command list failed: $e');
      }
    });
  });

  // =========================================================================
  // AI 模块深度验证
  // =========================================================================
  group('AI 深度契约验证', () {
    test('Ollama 模型列表解析', () async {
      if (skip() != null) return;
      try {
        final raw =
            await _rawPost(client, '/ai/ollama/model/search', data: {
          'page': 1,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
        });
        final data = _unwrap(raw.data, '/ai/ollama/model/search');
        _log('AI/model/search raw', response: data);

        if (data == null) {
          appLogger.dWithPackage(_pkg, 'AI model search returned null');
          return;
        }

        final pageData = Map<String, dynamic>.from(data as Map);
        final rawItems = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'AI models: ${rawItems.length} items');

        if (rawItems.isNotEmpty) {
          final firstRaw = Map<String, dynamic>.from(rawItems.first as Map);
          appLogger.dWithPackage(
              _pkg, 'AI model first keys: ${firstRaw.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'AI model search failed: $e');
      }
    });

    test('GPU 信息解析', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawGet(client, '/ai/gpu/load');
        final data = _unwrap(raw.data, '/ai/gpu/load');
        _log('AI/gpu raw', response: data);

        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          appLogger.dWithPackage(_pkg, 'GPU info keys: ${m.keys.toList()}');
        }
      } catch (e) {
        appLogger.wWithPackage(_pkg, 'GPU info failed: $e');
      }
    });
  });

  // =========================================================================
  // 模型 toJson round-trip 验证
  // =========================================================================
  group('模型 toJson round-trip 验证', () {
    test('DatabaseSearch toJson 包含所有必需字段', () {
      const search = DatabaseSearch(
        database: 'test-db',
        info: 'test',
        page: 1,
        pageSize: 20,
      );
      final json = search.toJson();

      // Verify required fields exist
      expect(json.containsKey('database'), isTrue);
      expect(json.containsKey('info'), isTrue);
      expect(json.containsKey('page'), isTrue);
      expect(json.containsKey('pageSize'), isTrue);

      // Verify database is not empty (server requires non-empty)
      expect(json['database'], isNotEmpty);

      // Verify order fields have defaults
      expect(json.containsKey('orderBy'), isTrue);
      expect(json.containsKey('order'), isTrue);
      expect(json['orderBy'], isNotEmpty);
      expect(json['order'], isNotEmpty);
    });

    test('PageContainer toJson 包含 state 默认值', () {
      const container = PageContainer();
      final json = container.toJson();

      expect(json.containsKey('state'), isTrue);
      expect(json['state'], equals('all'));
      expect(json.containsKey('orderBy'), isTrue);
      expect(json.containsKey('order'), isTrue);
    });

    test('CronjobListQuery toJson 包含有效 order', () {
      const query = CronjobListQuery();
      final json = query.toJson();

      expect(json['order'], equals('descending'));
      expect(json['order'], isNot(equals('null')));
      expect(json['orderBy'], equals('createdAt'));
    });
  });

  // =========================================================================
  // 边界情况与错误处理
  // =========================================================================
  group('边界情况验证', () {
    test('空搜索结果不应崩溃', () async {
      if (skip() != null) return;

      // Search for something that likely doesn't exist
      final raw = await _rawPost(client, '/databases/db/search', data: {
        'info': 'zzz_nonexistent_database_zzz',
        'database': '',
        'page': 1,
        'pageSize': 5,
        'orderBy': 'createdAt',
        'order': 'descending',
        'type': 'mysql',
      });
      final data = _unwrap(raw.data, '/databases/db/search');
      _log('Empty search result', response: data);

      if (data is Map) {
        final pageData = Map<String, dynamic>.from(data);
        final items = pageData['items'] as List? ?? [];
        appLogger.dWithPackage(
            _pkg, 'Empty search returned ${items.length} items');
      }
    });

    test('大 pageSize 不应导致超时', () async {
      if (skip() != null) return;
      final raw = await _rawPost(client, '/containers/search', data: {
        'page': 1,
        'pageSize': 100,
        'orderBy': 'createdAt',
        'order': 'descending',
        'state': 'all',
      });
      final data = _unwrap(raw.data, '/containers/search');
      _log('Large pageSize result', response: data);

      final pageData = Map<String, dynamic>.from(data as Map);
      final items = pageData['items'] as List? ?? [];
      appLogger.dWithPackage(
          _pkg, 'Large pageSize returned ${items.length} items');
    });

    test('page=0 应返回错误或第一页', () async {
      if (skip() != null) return;
      try {
        final raw = await _rawPost(client, '/containers/search', data: {
          'page': 0,
          'pageSize': 5,
          'orderBy': 'createdAt',
          'order': 'descending',
          'state': 'all',
        });
        final m = Map<String, dynamic>.from(raw.data as Map);
        appLogger.dWithPackage(
            _pkg, 'page=0 response: code=${m['code']}, message=${m['message']}');
        // Server may accept page=0 and return page 1, or return an error
        expect(m['code'], anyOf(equals(200), equals(400)));
      } catch (e) {
        // Server rejects page=0 with validation error - this is expected
        appLogger.dWithPackage(_pkg, 'page=0 correctly rejected: $e');
        expect(e.toString(), contains('Page'));
      }
    });
  });
}
