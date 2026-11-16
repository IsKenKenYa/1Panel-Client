import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';

class ServerConnectionResult {
  const ServerConnectionResult({
    required this.success,
    this.errorMessage,
    this.osInfo,
    this.responseTime,
  });

  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? osInfo;
  final Duration? responseTime;
}

class ServerConnectionService {
  Future<ServerConnectionResult> testConnection({
    required String serverUrl,
    required String apiKey,
    bool allowInsecureTls = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      if (allowInsecureTls && !kIsWeb) {
        try {
          (dio.httpClientAdapter as dynamic).onHttpClientCreate =
              (dynamic httpClient) {
            httpClient.badCertificateCallback =
                (dynamic cert, String host, int port) => true;
            return httpClient;
          };
        } catch (_) {
          // Ignore adapter-level failures and continue with default validation.
        }
      }

      final response = await dio.get(
        '/api/v2/dashboard/base/os',
        options: Options(headers: OnePanelAuthHeaders.build(apiKey)),
      );

      stopwatch.stop();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;
        if (data != null && data['data'] != null) {
          return ServerConnectionResult(
            success: true,
            osInfo: data['data'] as Map<String, dynamic>?,
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
      errorMessage:
          '$message (请在面板 API 接口设置中将 IP 白名单改为 0.0.0.0/0 或添加当前出口 IP)',
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
