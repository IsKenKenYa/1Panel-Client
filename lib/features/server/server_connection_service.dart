import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:onepanelapp_app/core/network/tls_bypass.dart';

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
    bool ignoreTls = false,
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

      if (ignoreTls) {
        configureTlsBypass(dio);
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final authString = '1panel$apiKey$timestamp';
      final bytes = utf8.encode(authString);
      final digest = md5.convert(bytes);
      final token = digest.toString();

      final response = await dio.get(
        '/api/v2/dashboard/base/os',
        options: Options(headers: {
          '1Panel-Token': token,
          '1Panel-Timestamp': timestamp,
        }),
      );

      stopwatch.stop();

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null) {
          return ServerConnectionResult(
            success: true,
            osInfo: data['data'] as Map<String, dynamic>?,
            responseTime: stopwatch.elapsed,
          );
        }
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
            errorMessage = 'Server error: ${e.response?.statusCode ?? 'Unknown'}';
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
