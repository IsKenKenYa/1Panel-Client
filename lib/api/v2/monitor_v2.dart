import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';

/// 监控搜索请求
///
/// 根据1PanelV2OpenAPI规范，请求参数为：
/// - param: 监控参数类型 (cpu/memory/load/io/network/all/base)
/// - startTime: 开始时间 (UTC ISO8601格式)
/// - endTime: 结束时间 (UTC ISO8601格式)
class MonitorSearch {
  final String param;
  final String? startTime;
  final String? endTime;

  const MonitorSearch({
    this.param = 'all',
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'param': param,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      };
}

/// GPU监控搜索请求
class MonitorGPUSearch {
  final String? startTime;
  final String? endTime;

  const MonitorGPUSearch({this.startTime, this.endTime});

  Map<String, dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      };
}

/// 监控数据项
///
/// API响应格式: {param: 'base', date: [...], value: [...]}
class MonitorDataItem {
  final String? param;
  final List<String>? date;
  final List<Map<String, dynamic>>? value;

  const MonitorDataItem({
    this.param,
    this.date,
    this.value,
  });

  factory MonitorDataItem.fromJson(Map<String, dynamic> json) {
    return MonitorDataItem(
      param: json['param'] as String?,
      date: (json['date'] as List?)?.map((e) => e.toString()).toList(),
      value: (json['value'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (param != null) 'param': param,
        if (date != null) 'date': date,
        if (value != null) 'value': value,
      };
}

/// 监控搜索响应
///
/// API响应格式: {code: 200, message: '', data: [MonitorDataItem...]}
class MonitorSearchResponse {
  final int? code;
  final String? message;
  final List<MonitorDataItem>? data;

  const MonitorSearchResponse({
    this.code,
    this.message,
    this.data,
  });

  factory MonitorSearchResponse.fromJson(Map<String, dynamic> json) {
    return MonitorSearchResponse(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: (json['data'] as List?)
          ?.map((e) => MonitorDataItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (data != null) 'data': data?.map((e) => e.toJson()).toList(),
      };
}

/// GPU信息
class GPUInfo {
  final String? name;
  final double? utilization;
  final double? memory;
  final double? temperature;

  const GPUInfo({
    this.name,
    this.utilization,
    this.memory,
    this.temperature,
  });

  factory GPUInfo.fromJson(Map<String, dynamic> json) {
    return GPUInfo(
      name: json['name'] as String?,
      utilization: (json['utilization'] as num?)?.toDouble(),
      memory: (json['memory'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (utilization != null) 'utilization': utilization,
        if (memory != null) 'memory': memory,
        if (temperature != null) 'temperature': temperature,
      };
}

/// GPU监控数据
class MonitorGPUData {
  final List<GPUInfo>? data;

  const MonitorGPUData({this.data});

  factory MonitorGPUData.fromJson(Map<String, dynamic> json) {
    return MonitorGPUData(
      data: (json['data'] as List?)
          ?.map((item) => GPUInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 监控设置
class MonitorSetting {
  final int? interval;
  final int? retention;
  final bool? enabled;
  final String? defaultNetwork;
  final String? defaultIO;

  const MonitorSetting({
    this.interval,
    this.retention,
    this.enabled,
    this.defaultNetwork,
    this.defaultIO,
  });

  factory MonitorSetting.fromJson(Map<String, dynamic> json) {
    final intervalRaw = json['monitorInterval'] ?? json['MonitorInterval'];
    final retentionRaw =
        json['monitorStoreDays'] ?? json['MonitorStoreDays'];
    final statusRaw = json['monitorStatus'] ?? json['MonitorStatus'];
    final defaultNetworkRaw =
        json['defaultNetwork'] ?? json['DefaultNetwork'];
    final defaultIORaw = json['defaultIO'] ?? json['DefaultIO'];

    bool? enabled;
    if (statusRaw is bool) {
      enabled = statusRaw;
    } else if (statusRaw != null) {
      final normalized = statusRaw.toString().toLowerCase();
      if (normalized == 'enable' ||
          normalized == 'enabled' ||
          normalized == 'true' ||
          normalized == '1') {
        enabled = true;
      } else if (normalized == 'disable' ||
          normalized == 'disabled' ||
          normalized == 'false' ||
          normalized == '0') {
        enabled = false;
      }
    }

    return MonitorSetting(
      interval: int.tryParse(intervalRaw?.toString() ?? ''),
      retention: int.tryParse(retentionRaw?.toString() ?? ''),
      enabled: enabled,
      defaultNetwork: defaultNetworkRaw?.toString(),
      defaultIO: defaultIORaw?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (interval != null) 'monitorInterval': interval,
        if (retention != null) 'monitorStoreDays': retention,
        if (enabled != null)
          'monitorStatus': (enabled == true) ? 'Enable' : 'Disable',
        if (defaultNetwork != null) 'defaultNetwork': defaultNetwork,
        if (defaultIO != null) 'defaultIO': defaultIO,
      };
}

/// 监控设置更新请求
class MonitorSettingUpdate {
  final int? interval;
  final int? retention;
  final bool? enabled;

  const MonitorSettingUpdate({
    this.interval,
    this.retention,
    this.enabled,
  });

  List<Map<String, dynamic>> toUpdateItems() {
    final items = <Map<String, dynamic>>[];
    if (interval != null) {
      items.add({'key': 'MonitorInterval', 'value': interval});
    }
    if (retention != null) {
      items.add({'key': 'MonitorStoreDays', 'value': retention});
    }
    if (enabled != null) {
      items.add({
        'key': 'MonitorStatus',
        'value': (enabled == true) ? 'Enable' : 'Disable',
      });
    }
    return items;
  }

  Map<String, dynamic> toJson() => {
        if (interval != null) 'monitorInterval': interval,
        if (retention != null) 'monitorStoreDays': retention,
        if (enabled != null)
          'monitorStatus': (enabled == true) ? 'Enable' : 'Disable',
      };
}

/// Monitor V2 API客户端
///
/// 基于1PanelV2OpenAPI规范实现
/// 端点: /hosts/monitor/search, /hosts/monitor/setting, /hosts/monitor/clean
class MonitorV2Api {
  final DioClient _client;

  MonitorV2Api(this._client);

  /// 搜索监控数据
  ///
  /// POST /hosts/monitor/search
  /// @param request 监控搜索请求
  /// @return 监控搜索响应
  Future<Response<MonitorSearchResponse>> search(MonitorSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/monitor/search'),
      data: request.toJson(),
    );
    return Response(
      data:
          MonitorSearchResponse.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取GPU监控数据
  ///
  /// POST /hosts/monitor/gpu/search
  Future<Response<MonitorGPUData>> searchGPU(MonitorGPUSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/monitor/gpu/search'),
      data: request.toJson(),
    );
    return Response(
      data: MonitorGPUData.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 清理监控数据
  ///
  /// POST /hosts/monitor/clean
  Future<Response> clean() async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/monitor/clean'),
    );
  }

  /// 获取监控设置
  ///
  /// GET /hosts/monitor/setting
  Future<Response<MonitorSetting>> getSetting() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/monitor/setting'),
    );
    final data = response.data as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>? ?? data;
    return Response(
      data: MonitorSetting.fromJson(payload),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新监控设置
  ///
  /// POST /hosts/monitor/setting/update
  Future<Response> updateSetting(MonitorSettingUpdate request) async {
    final updates = request.toUpdateItems();
    if (updates.isEmpty) {
      return await _client.post(
        ApiConstants.buildApiPath('/hosts/monitor/setting/update'),
        data: request.toJson(),
      );
    }

    Response? lastResponse;
    for (final item in updates) {
      lastResponse = await _client.post(
        ApiConstants.buildApiPath('/hosts/monitor/setting/update'),
        data: item,
      );
    }
    return lastResponse!;
  }

  // ==================== 便捷方法 ====================

  /// 获取所有监控数据
  Future<Response<MonitorSearchResponse>> getAllMetrics({
    String? startTime,
    String? endTime,
  }) async {
    return search(MonitorSearch(
      param: 'all',
      startTime: startTime,
      endTime: endTime,
    ));
  }

  /// 获取基础监控数据 (CPU, 内存, 负载)
  Future<Response<MonitorSearchResponse>> getBaseMetrics({
    String? startTime,
    String? endTime,
  }) async {
    return search(MonitorSearch(
      param: 'base',
      startTime: startTime,
      endTime: endTime,
    ));
  }

  /// 获取IO监控数据 (磁盘)
  Future<Response<MonitorSearchResponse>> getIOMetrics({
    String? startTime,
    String? endTime,
  }) async {
    return search(MonitorSearch(
      param: 'io',
      startTime: startTime,
      endTime: endTime,
    ));
  }

  /// 获取网络监控数据
  Future<Response<MonitorSearchResponse>> getNetworkMetrics({
    String? startTime,
    String? endTime,
  }) async {
    return search(MonitorSearch(
      param: 'network',
      startTime: startTime,
      endTime: endTime,
    ));
  }
}
