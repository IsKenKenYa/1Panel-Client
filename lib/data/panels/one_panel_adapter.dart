import 'package:dio/dio.dart';
import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/api/v2/health_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/interceptors/retry_interceptor.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/server_connection_result.dart';
import 'package:onepanel_client/data/models/server_metrics_snapshot.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'panel_adapter.dart';

class OnePanelAdapter implements PanelAdapter {
  const OnePanelAdapter({ApiClientManager? clientManager})
      : _clientManager = clientManager;

  final ApiClientManager? _clientManager;

  @override
  String get panelType => ApiConfig.onePanelType;

  @override
  OnePanelSession open(ApiConfig config, {bool temporary = false}) {
    config.requireOnePanel();
    final manager = _clientManager;
    if (!temporary && manager != null) {
      final client = manager.getClientForConfig(config);
      return OnePanelSession._(
        client,
        () => manager.removeClient(config.id, expected: client),
      );
    }
    final client = DioClient(
      baseUrl: config.url,
      apiKey: config.apiKey,
      allowInsecureTls: config.allowInsecureTls,
    );
    return OnePanelSession._(client, () => client.dio.close(force: true));
  }
}

class OnePanelSession implements PanelSession {
  OnePanelSession._(this.client, this._close);

  final DioClient client;
  final void Function() _close;

  @override
  Future<Map<String, PanelAccess>> loadCapabilities() async => const {
        'connection': PanelAccess.read,
        'metrics': PanelAccess.read,
      };

  @override
  Future<ServerMetricsSnapshot> loadMetrics() async {
    final (metrics, latency) = await (
      DashboardRepository(api: DashboardV2Api(client)).getCurrentServerMetrics(),
      _probe(),
    ).wait;
    return metrics.copyWith(isReachable: latency != null, latencyMs: latency);
  }

  Future<int?> _probe() async {
    final stopwatch = Stopwatch()..start();
    try {
      await HealthV2Api(client).checkHealth();
      return stopwatch.elapsedMilliseconds;
    } on NetworkException {
      return null;
    }
  }

  @override
  void close() => _close();

  @override
  Future<ServerConnectionResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await client.dio.get<dynamic>(
        ApiConstants.buildApiPath(ApiPaths.dashboardBaseOs),
        options: Options(extra: {RetryInterceptor.disableRetryKey: true}),
      );

      stopwatch.stop();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;
        if (data != null && (data['code'] == null || data['code'] == 200) &&
            data['data'] is Map<String, dynamic>) {
          final os = (data['data'] as Map<String, dynamic>)['os'];
          return ServerConnectionResult(
            success: true,
            operatingSystem: os is String && os.isNotEmpty ? os : null,
            responseTime: stopwatch.elapsed,
          );
        }
        // 1Panel 业务层错误（HTTP 200 + code != 200）透出服务端原因，
        // 例如 IP 白名单拒绝：{"code":401,"message":"调用 API 接口 IP 不在白名单"}。
        return resolveConnectionFailure(data, stopwatch.elapsed);
      }

      return ServerConnectionResult(
        success: false,
        errorMessage: 'Invalid response from server',
        responseTime: stopwatch.elapsed,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['message'] is String) {
        return resolveConnectionFailure(body, stopwatch.elapsed);
      }
      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            errorMessage = 'Authentication failed: Invalid API key';
          } else {
            errorMessage =
                'Server error: ${e.response?.statusCode ?? 'Unknown'}';
          }
          break;
        default:
          errorMessage = 'Connection failed: ${e.message}';
      }

      return ServerConnectionResult(
        success: false,
        errorMessage: errorMessage,
        responseTime: stopwatch.elapsed,
        isNetworkError: e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout,
      );
    } catch (e) {
      stopwatch.stop();
      return ServerConnectionResult(
        success: false,
        errorMessage: 'Unexpected error: $e',
        responseTime: stopwatch.elapsed,
      );
    }
  }
}

/// 将 1Panel 业务层错误响应解析为可诊断的失败结果。
///
/// 1Panel 拒绝请求时返回 HTTP 200 + 业务 code（如白名单 401），
/// 服务端 message 是唯一可用的诊断信息，必须透出而非笼统报错。
ServerConnectionResult resolveConnectionFailure(
  Map<String, dynamic>? data,
  Duration elapsed,
) {
  final message = data?['message']?.toString() ?? '';
  if (message.contains('白名单') || message.toLowerCase().contains('whitelist')) {
    return ServerConnectionResult(
      success: false,
      errorMessage: '$message (请在面板 API 接口设置的 IP 白名单中添加当前出口 IP)',
      responseTime: elapsed,
    );
  }
  if (message.isNotEmpty) {
    return ServerConnectionResult(
      success: false,
      errorMessage: message,
      responseTime: elapsed,
    );
  }
  return ServerConnectionResult(
    success: false,
    errorMessage: 'Invalid response from server',
    responseTime: elapsed,
  );
}
