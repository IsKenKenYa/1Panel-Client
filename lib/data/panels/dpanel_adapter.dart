import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/browser_connection_policy.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/server_connection_result.dart';
import 'package:onepanel_client/data/models/server_metrics_snapshot.dart';

import 'panel_adapter.dart';

class DPanelOverview {
  const DPanelOverview({
    this.panelVersion,
    this.operatingSystem,
    this.dockerVersion,
    this.environmentName,
    this.containerCount,
    this.runningCount,
  });

  final String? panelVersion;
  final String? operatingSystem;
  final String? dockerVersion;
  final String? environmentName;
  final int? containerCount;
  final int? runningCount;
}

class DPanelContainerSummary {
  const DPanelContainerSummary({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.status,
  });

  final String id;
  final String name;
  final String image;
  final String state;
  final String status;

  bool get isRunning => state.toLowerCase() == 'running';
}

class DPanelAdapter implements PanelAdapter {
  const DPanelAdapter({this.dioFactory});

  static const String panelTypeId = 'dpanel';
  static const String fieldUsername = 'username';
  static const String fieldPassword = 'password';
  static const String fieldEntrance = 'entrance';
  static const String fieldTotpCode = 'totpCode';

  final Dio Function(ApiConfig config)? dioFactory;

  @override
  String get panelType => panelTypeId;

  @override
  DPanelSession open(ApiConfig config, {bool temporary = false}) {
    if (config.panelType != panelTypeId) {
      throw UnsupportedError('This operation requires a DPanel connection');
    }
    final dio = dioFactory?.call(config) ?? _createDio(config);
    return DPanelSession(config: config, dio: dio);
  }

  static Dio _createDio(ApiConfig config) {
    final baseUrl = normalizeBaseUrl(config.url);
    if (kIsWeb && BrowserConnectionPolicy.issue(baseUrl) != null) {
      throw ArgumentError('需要有效的 HTTP 或 HTTPS 面板地址');
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    if (config.allowInsecureTls && !kIsWeb) {
      try {
        (dio.httpClientAdapter as dynamic).onHttpClientCreate =
            (dynamic httpClient) {
              httpClient.badCertificateCallback =
                  (dynamic cert, String host, int port) => true;
              return httpClient;
            };
        appLogger.wWithPackage('data.panels.dpanel', '当前连接允许未受信任的 TLS 证书');
      } catch (_) {
        appLogger.wWithPackage('data.panels.dpanel', '当前 HTTP 适配器无法应用 TLS 证书设置');
      }
    }
    return dio;
  }

  static String normalizeBaseUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/dpanel/api')) {
      trimmed = trimmed.substring(0, trimmed.length - '/dpanel/api'.length);
    }
    return trimmed;
  }
}

class DPanelSession implements PanelSession {
  DPanelSession({required this.config, required Dio dio}) : _dio = dio;

  final ApiConfig config;
  final Dio _dio;
  String? _accessToken;
  String? _entranceCookie;
  Future<String>? _loginInFlight;

  String get _apiPrefix => '/dpanel/api';

  @override
  void close() {
    _accessToken = null;
    _entranceCookie = null;
    _dio.close(force: true);
  }

  @override
  Future<ServerConnectionResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _ensureToken(forceRefresh: true);
      final overview = await loadOverview();
      stopwatch.stop();
      final parts = [
        if (overview.operatingSystem case final os? when os.isNotEmpty) os,
        if (overview.panelVersion case final ver? when ver.isNotEmpty)
          'DPanel $ver',
      ];
      return ServerConnectionResult(
        success: true,
        operatingSystem: parts.isEmpty ? 'DPanel' : parts.join(' · '),
        responseTime: stopwatch.elapsed,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return ServerConnectionResult(
        success: false,
        errorMessage: _extractDioErrorMessage(e),
        responseTime: stopwatch.elapsed,
        isNetworkError:
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout,
      );
    } catch (e) {
      stopwatch.stop();
      return ServerConnectionResult(
        success: false,
        errorMessage: e.toString(),
        responseTime: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<Map<String, PanelAccess>> loadCapabilities() async {
    final payload = await _postAuthorized('/common/user/get-user-info');
    final features = <String>{
      for (final item in _readList(payload['feature'])) item.toString(),
    };
    return <String, PanelAccess>{
      'connection': PanelAccess.read,
      'metrics': PanelAccess.read,
      'containers': PanelAccess.write,
      if (features.contains('version-env-standard')) 'sites': PanelAccess.read,
      if (features.contains('swarm-manage')) 'swarm': PanelAccess.read,
    };
  }

  @override
  Future<ServerMetricsSnapshot> loadMetrics() async {
    final stopwatch = Stopwatch()..start();
    try {
      final statPayload = await _postAuthorized(
        '/common/home/get-stat-list',
        data: const {'follow': false},
      );
      stopwatch.stop();
      final system = _asMap(statPayload['system']);
      final cpu = _asMap(system?['cpu']);
      final memory = _asMap(system?['memory']);

      final cpuPercent = _toDouble(cpu?['usagePercent']);
      final load1 = _toDouble(cpu?['load1']);
      final memTotal = _toDouble(memory?['total']);
      final memAvailable = _toDouble(memory?['available']);
      double? memoryPercent;
      if (memTotal != null && memTotal > 0 && memAvailable != null) {
        memoryPercent =
            ((memTotal - memAvailable) / memTotal * 100).clamp(0.0, 100.0);
      }

      return ServerMetricsSnapshot(
        cpuPercent: cpuPercent,
        memoryPercent: memoryPercent,
        load: load1,
        isReachable: true,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      return const ServerMetricsSnapshot(isReachable: false);
    }
  }

  Future<DPanelOverview> loadOverview() async {
    final payload = await _postAuthorized('/common/home/info');
    final info = _asMap(payload['info']);
    final dpanel = _asMap(payload['dpanel']);
    final dockerEnv = _asMap(payload['dockerEnv']);
    final envTitle = _nonEmptyString(dockerEnv?['title']);
    final envName = _nonEmptyString(dockerEnv?['name']);
    return DPanelOverview(
      panelVersion: _nonEmptyString(dpanel?['version']),
      operatingSystem: _nonEmptyString(info?['OperatingSystem']),
      dockerVersion: _nonEmptyString(info?['ServerVersion']),
      environmentName: envTitle ?? envName,
      containerCount: _toInt(info?['Containers']),
      runningCount: _toInt(info?['ContainersRunning']),
    );
  }

  Future<List<DPanelContainerSummary>> listContainers() async {
    final payload = await _postAuthorized('/app/container/get-list');
    final items = _readList(payload['list']);
    final result = <DPanelContainerSummary>[];
    for (final raw in items) {
      final item = _asMap(raw);
      if (item == null) continue;
      final id = _nonEmptyString(item['Id']) ?? _nonEmptyString(item['id']);
      if (id == null) continue;
      final names = _readList(item['Names']);
      final rawName = names.isNotEmpty
          ? names.first.toString()
          : _nonEmptyString(item['name']) ?? id;
      final name = rawName.startsWith('/') ? rawName.substring(1) : rawName;
      result.add(
        DPanelContainerSummary(
          id: id,
          name: name,
          image: _nonEmptyString(item['Image']) ?? '',
          state: _nonEmptyString(item['State']) ?? '',
          status: _nonEmptyString(item['Status']) ?? '',
        ),
      );
    }
    return result;
  }

  Future<void> operateContainer(String containerId, String operate) async {
    const allowed = {'start', 'stop', 'restart', 'pause', 'unpause'};
    if (!allowed.contains(operate)) {
      throw ArgumentError.value(operate, 'operate');
    }
    await _postAuthorized(
      '/app/container/status',
      data: {'md5': containerId, 'operate': operate},
    );
  }

  Future<Map<String, dynamic>> _postAuthorized(
    String apiPath, {
    Map<String, dynamic> data = const {},
  }) async {
    final token = await _ensureToken();
    try {
      return await _postWithToken(apiPath, token, data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) rethrow;
      _accessToken = null;
      final refreshed = await _ensureToken(forceRefresh: true);
      return _postWithToken(apiPath, refreshed, data: data);
    }
  }

  Future<Map<String, dynamic>> _postWithToken(
    String apiPath,
    String token, {
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.post<dynamic>(
      '$_apiPrefix$apiPath',
      data: data,
      options: Options(
        headers: {
          'X-DPanel-Authorization': 'Bearer $token',
          if (_entranceCookie != null) 'Cookie': _entranceCookie!,
        },
      ),
    );
    return _unwrapPayload(response.data);
  }

  Future<String> _ensureToken({bool forceRefresh = false}) {
    if (!forceRefresh && _accessToken != null && _accessToken!.isNotEmpty) {
      return Future.value(_accessToken!);
    }
    final pending = _loginInFlight;
    if (pending != null) return pending;
    final op = _login().whenComplete(() => _loginInFlight = null);
    _loginInFlight = op;
    return op;
  }

  Future<String> _login() async {
    final username =
        (config.additionalCredentials[DPanelAdapter.fieldUsername] ?? '')
            .trim();
    final password =
        config.additionalCredentials[DPanelAdapter.fieldPassword] ?? '';
    final entrance =
        (config.additionalCredentials[DPanelAdapter.fieldEntrance] ?? '')
            .trim();
    final totpCode =
        (config.additionalCredentials[DPanelAdapter.fieldTotpCode] ?? '')
            .trim();
    if (username.isEmpty || password.isEmpty) {
      throw StateError('DPanel username and password are required');
    }

    if (entrance.isNotEmpty) {
      await _acquireEntranceCookie(entrance);
    }

    final response = await _dio.post<dynamic>(
      '$_apiPrefix/common/user/login',
      data: {
        'username': username,
        'password': password,
        'autoLogin': true,
        if (totpCode.isNotEmpty) 'code': totpCode,
      },
      options: Options(
        headers: {if (_entranceCookie != null) 'Cookie': _entranceCookie!},
      ),
    );
    final payload = _unwrapPayload(response.data);
    final token = _nonEmptyString(payload['accessToken']);
    if (token == null) {
      throw StateError('DPanel login response did not include an accessToken');
    }
    _accessToken = token;
    return token;
  }

  Future<void> _acquireEntranceCookie(String entrance) async {
    final normalized = entrance.startsWith('/') ? entrance : '/$entrance';
    final response = await _dio.get<dynamic>(
      normalized,
      options: Options(
        followRedirects: false,
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    final cookies = response.headers['set-cookie'] ?? const <String>[];
    for (final header in cookies) {
      final pair = header.split(';').first.trim();
      if (pair.startsWith('DPanelEntrance=')) {
        _entranceCookie = pair;
        return;
      }
    }
  }

  static Map<String, dynamic> _unwrapPayload(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) {
      throw FormatException('Unexpected DPanel response format');
    }
    final errorText =
        _nonEmptyString(map['error']) ?? _nonEmptyString(map['message']);
    final code = map['code'];
    if (code is int && code != 200 && code != 0) {
      throw StateError(errorText ?? 'DPanel request rejected ($code)');
    }
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    if (code == null && errorText != null && map['accessToken'] == null) {
      throw StateError(errorText);
    }
    return map;
  }

  static String _extractDioErrorMessage(DioException e) {
    final body = _asMap(e.response?.data);
    final message =
        _nonEmptyString(body?['error']) ?? _nonEmptyString(body?['message']);
    if (message != null) return message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server';
      case DioExceptionType.badCertificate:
        return 'TLS certificate verification failed';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) return 'Authentication failed';
        return 'Server error ($status)';
      default:
        return e.message ?? 'Connection failed';
    }
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static List<dynamic> _readList(dynamic value) =>
      value is List ? value : const [];

  static String? _nonEmptyString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
