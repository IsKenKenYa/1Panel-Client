import '../../../api/v2/file_v2.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../core/services/logger/logger_service.dart';

class FilesApiGateway {
  FileV2Api? _api;
  String? _currentServerId;
  String? _currentApiKey;

  Future<FileV2Api> getApi() async {
    appLogger.dWithPackage('files.gateway', 'getApi');
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
