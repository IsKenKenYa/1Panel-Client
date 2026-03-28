import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

class FilesRepository {
  FilesRepository({FileV2Api? api}) : _api = api;

  FileV2Api? _api;
  String? _currentServerId;
  String? _currentApiKey;

  Future<FileV2Api> getApi() async {
    if (_api != null && _currentServerId == null && _currentApiKey == null) {
      return _api!;
    }

    appLogger.dWithPackage('files.repository', 'getApi');
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No server configured');
    }

    if (_api == null ||
        _currentServerId != config.id ||
        _currentApiKey != config.apiKey) {
      final client = await ApiClientManager.instance.getCurrentClient();
      _api = FileV2Api(client);
      _currentServerId = config.id;
      _currentApiKey = config.apiKey;
    }

    return _api!;
  }

  Future<ApiConfig?> getCurrentServer() async {
    return ApiConfigManager.getCurrentConfig();
  }

  void clearCache() {
    _api = null;
    _currentServerId = null;
    _currentApiKey = null;
  }
}