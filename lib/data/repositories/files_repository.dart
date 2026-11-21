import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

class FilesRepository {
  FilesRepository({FileV2Api? api}) : _api = api;

  FileV2Api? _api;
  DioClient? _client;

  /// Returns cached API instance, or rebuilds it when the active server changes.
  Future<FileV2Api> getApi() async {
    if (_api != null && _client == null) {
      return _api!;
    }

    appLogger.dWithPackage('files.repository', 'getApi');
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw const NetworkConnectionException('未配置服务器连接');
    }

    return getApiForConfig(config);
  }

  FileV2Api getApiForConfig(ApiConfig config) {
    if (_api != null && _client == null) return _api!;
    final client = ApiClientManager.instance.getClientForConfig(config);
    if (!identical(client, _client)) {
      _api = FileV2Api(client);
      _client = client;
    }

    return _api!;
  }

  Future<ApiConfig?> getCurrentServer() async {
    return ApiConfigManager.getCurrentConfig();
  }

  void clearCache() {
    _api = null;
    _client = null;
  }
}
