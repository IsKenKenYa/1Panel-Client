import 'package:onepanel_client/api/v2/openresty_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';

class OpenRestyRepository {
  OpenRestyRepository({OpenRestyV2Api? api}) : _api = api;

  OpenRestyV2Api? _api;

  Future<OpenRestyV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getOpenRestyApi();
    return _api!;
  }

  Future<OpenrestyStatus?> getStatus() async {
    final api = await _ensureApi();
    return (await api.getOpenRestyStatus()).data;
  }

  Future<OpenrestyBuildConfig?> getModules() async {
    final api = await _ensureApi();
    return (await api.getOpenRestyModules()).data;
  }

  Future<OpenrestyHttpsConfig?> getHttps() async {
    final api = await _ensureApi();
    return (await api.getOpenRestyHttps()).data;
  }

  Future<OpenrestyFile?> getConfig() async {
    final api = await _ensureApi();
    return (await api.getOpenRestyConfig()).data;
  }

  Future<void> updateHttps(OpenrestyDefaultHttpsUpdateRequest request) async {
    final api = await _ensureApi();
    await api.updateOpenRestyHttps(request);
  }

  Future<void> updateModules(OpenrestyModuleUpdateRequest request) async {
    final api = await _ensureApi();
    await api.updateOpenRestyModules(request);
  }

  Future<void> updateConfig(OpenrestyConfigFileUpdateRequest request) async {
    final api = await _ensureApi();
    await api.updateOpenRestyConfigByFile(request);
  }

  Future<void> build(OpenrestyBuildRequest request) async {
    final api = await _ensureApi();
    await api.buildOpenResty(request);
  }

  Future<List<OpenrestyParam>> getScope(OpenrestyScopeRequest request) async {
    final api = await _ensureApi();
    return (await api.getOpenRestyScope(request)).data ?? const [];
  }
}
