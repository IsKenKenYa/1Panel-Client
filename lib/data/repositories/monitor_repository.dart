import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/monitor_models.dart';
import '../models/monitoring_runtime_models.dart';
import '../../core/services/logger/logger_service.dart';

const String _monitorRepoPackage = 'data.repositories.monitor_repository';

/// Unified monitoring data repository.
///
/// Provides a single entry point for monitoring data retrieval, avoiding
/// code duplication. Data model classes and parse functions live in
/// `lib/data/models/monitor_models.dart` (architecture review candidate
/// ㉑ -- model responsibility was previously inlined in this repository).
class MonitorRepository {
  const MonitorRepository();

  /// Fetches the current monitoring metrics snapshot.
  Future<MonitorMetricsSnapshot> getCurrentMetrics(dynamic client) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));

      final response = await client.post(
        '/api/v2/hosts/monitor/search',
        data: {
          'param': 'all',
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': now.toUtc().toIso8601String(),
        },
      );

      return parseMetricsResponse(response.data, now);
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'getCurrentMetrics failed',
        error: e,
        stackTrace: stack,
      );
      return const MonitorMetricsSnapshot();
    }
  }

  /// Fetches a time series for [param]/[valueKey] over [duration].
  Future<MonitorTimeSeries> getTimeSeries(
    dynamic client,
    String param,
    String valueKey, {
    String? io,
    String? network,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(duration);

      final response = await client.post(
        '/api/v2/hosts/monitor/search',
        data: {
          'param': 'all',
          if (io != null) 'io': io,
          if (network != null) 'network': network,
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': now.toUtc().toIso8601String(),
        },
      );

      return parseTimeSeriesResponse(response.data, param, valueKey);
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'getTimeSeries failed: param=$param valueKey=$valueKey',
        error: e,
        stackTrace: stack,
      );
      return MonitorTimeSeries.empty(param);
    }
  }

  /// Batch-fetches all monitoring data (current metrics + time series).
  Future<MonitorDataPackage> getMonitorData(
    dynamic client, {
    CancelToken? cancelToken,
    String? io,
    String? network,
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final now = endTime ?? DateTime.now();
    final start = startTime ?? now.subtract(duration);

    final response = await client.post(
      '/api/v2/hosts/monitor/search',
      cancelToken: cancelToken,
      data: {
        'param': 'all',
        if (io != null) 'io': io,
        if (network != null) 'network': network,
        'startTime': start.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      },
    );

    final body = response.data;
    if (body is! Map<String, dynamic> ||
        !body.containsKey('data') ||
        (body['data'] != null && body['data'] is! List)) {
      throw const FormatException('Invalid monitor history response');
    }
    final args = MonitorDataParseArgs(body, now);
    final groups = body['data'] as List?;
    if (groups == null ||
        groups.every((group) =>
            group is Map && ((group['value'] as List?)?.length ?? 0) <= 16)) {
      return parseMonitorDataPackage(args);
    }
    return compute(parseMonitorDataPackage, args);
  }

  /// Fetches GPU information.
  ///
  /// V2 契约：POST /ai/gpu/search 的 data 为 MonitorGPUData Map（时间序列
  /// 数组，见上游 frontend/src/api/interface/ai.ts MonitorGPUData），并非
  /// GPU 列表；旧实现按 List 解析必然失败。这里取各序列最后一个采样点
  /// 还原当前 GPU 状态，并兼容 data 为空 / 字段缺失。
  ///
  /// 上游 service 要求 search 必须携带设备（deviceID/productName），先经
  /// GET /ai/gpu/options 取设备列表；无 GPU 设备时直接返回空，不再发起
  /// 必然 500 的历史查询。
  Future<List<MonitorGpuInfo>> getGPUInfo(dynamic client) async {
    String? deviceId;
    String? productName;
    bool legacy = false;
    final optionsResponse = await client.get('/api/v2/ai/gpu/options');
    if (optionsResponse.data is Map) {
      final body = Map<String, dynamic>.from(optionsResponse.data as Map);
      final payload = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final chartHide = payload['chartHide'];
      if (chartHide is List && chartHide.isNotEmpty) {
        final first = Map<String, dynamic>.from(chartHide.first as Map);
        deviceId = (first['deviceID'] as String?)?.trim();
        productName = (first['productName'] as String?)?.trim();
        legacy = first['legacy'] == true;
      }
    }
    if ((deviceId == null || deviceId.isEmpty) &&
        (productName == null || productName.isEmpty)) {
      return [];
    }

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 1));

    final response = await client.post(
      '/api/v2/ai/gpu/search',
      data: {
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
        'deviceID': deviceId ?? '',
        'productName': productName ?? '',
        'legacy': legacy,
      },
    );

    if (response.data is Map) {
      final body = Map<String, dynamic>.from(response.data as Map);
      // 兼容信封 {code, message, data} 与已解包的 MonitorGPUData 两种形态。
      final payload = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return MonitorGpuInfo.listFromGpuSearchData(payload);
    }
    throw const FormatException('Invalid GPU history response');
  }

  /// Fetches monitoring settings.
  Future<MonitorSetting?> getSetting(dynamic client,
      {bool requireResponse = false}) async {
    try {
      final response = await client.get('/api/v2/hosts/monitor/setting');
      if (response.data != null && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        final payload = body['data'];
        if (payload is Map<String, dynamic>) {
          return MonitorSetting.fromJson(payload);
        }
        return MonitorSetting.fromJson(body);
      }
      if (requireResponse) {
        throw const FormatException('Invalid monitor settings response');
      }
      return null;
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'getSetting failed',
        error: e,
        stackTrace: stack,
      );
      if (requireResponse) rethrow;
      return null;
    }
  }

  /// Updates monitoring settings.
  Future<bool> updateSetting(
    dynamic client, {
    int? interval,
    int? retention,
    bool? enabled,
    String? defaultIO,
    String? defaultNetwork,
  }) async {
    try {
      final updates = <Map<String, dynamic>>[];
      if (interval != null) {
        updates.add({'key': 'MonitorInterval', 'value': interval.toString()});
      }
      if (retention != null) {
        updates.add({'key': 'MonitorStoreDays', 'value': retention.toString()});
      }
      if (enabled != null) {
        updates.add({
          'key': 'MonitorStatus',
          'value': enabled ? 'Enable' : 'Disable',
        });
      }
      if (defaultIO != null) {
        updates.add({'key': 'DefaultIO', 'value': defaultIO});
      }
      if (defaultNetwork != null) {
        updates.add({'key': 'DefaultNetwork', 'value': defaultNetwork});
      }

      for (final update in updates) {
        await client.post(
          '/api/v2/hosts/monitor/setting/update',
          data: update,
        );
      }
      return true;
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'updateSetting failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Cleans monitoring data.
  Future<bool> cleanData(dynamic client) async {
    try {
      await client.post('/api/v2/hosts/monitor/clean', data: {'type': 'host'});
      return true;
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'cleanData failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Fetches the list of network interfaces.
  Future<List<String>> getNetworkOptions(dynamic client,
          {bool requireResponse = false}) =>
      _getOptions(client, '/api/v2/hosts/monitor/netoptions', requireResponse);

  /// Fetches the list of IO devices.
  Future<List<String>> getIOOptions(dynamic client,
          {bool requireResponse = false}) =>
      _getOptions(client, '/api/v2/hosts/monitor/iooptions', requireResponse);

  Future<List<String>> _getOptions(
      dynamic client, String path, bool requireResponse) async {
    try {
      final response = await client.get(path);
      final body = response.data;
      if (body is Map && body['data'] is List) {
        return List<String>.from(body['data'] as List);
      }
      throw const FormatException('Invalid monitor device list');
    } catch (e, stack) {
      appLogger.eWithPackage(
        _monitorRepoPackage,
        'Failed to load monitor options from $path',
        error: e,
        stackTrace: stack,
      );
      if (requireResponse) rethrow;
      return const ['all'];
    }
  }
}
