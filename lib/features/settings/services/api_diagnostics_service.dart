import 'package:dio/dio.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

abstract final class ApiDiagnosticsService {
  static const endpoints = [
    '/api/v2/dashboard/base/os',
    '/api/v2/system/host',
    '/api/v2/system/load',
    '/api/v2/apps',
    '/api/v2/containers',
    '/api/v2/websites',
  ];

  static Future<ApiConfig?> currentServer() =>
      ApiConfigManager.getCurrentConfig();

  static Future<Response<dynamic>> check(ApiConfig config, String endpoint) {
    if (!endpoints.contains(endpoint)) throw ArgumentError.value(endpoint);
    return ApiClientManager.instance.getClientForConfig(config).get(endpoint);
  }
}
