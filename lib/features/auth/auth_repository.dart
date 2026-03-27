import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/auth_models.dart';

class AuthRepository {
  AuthRepository({AuthV2Api? apiClient}) : _apiClient = apiClient;

  AuthV2Api? _apiClient;

  Future<AuthV2Api> _getApi() async {
    _apiClient ??= await ApiClientManager.instance.getAuthApi();
    return _apiClient!;
  }

  Future<LoginSettings?> fetchLoginSettings() async {
    final api = await _getApi();
    final response = await api.getLoginSettings();
    final data = response.data;
    if (data == null) return null;
    return LoginSettings.fromJson(data);
  }

  Future<CaptchaData?> fetchCaptcha() async {
    final api = await _getApi();
    final data = (await api.getCaptcha()).data;
    if (data == null || data.isEmpty) return null;
    return CaptchaData(base64: data);
  }

  Future<DemoModeStatus?> fetchDemoModeStatus() async {
    final api = await _getApi();
    final data = (await api.checkDemoMode()).data;
    if (data == null) return null;
    return DemoModeStatus.fromJson(data);
  }

  Future<LoginResponse?> login(LoginRequest request) async {
    final api = await _getApi();
    final data = (await api.login(request.toJson())).data;
    if (data == null) return null;
    return LoginResponse.fromJson(data);
  }

  Future<LoginResponse?> mfaLogin(MfaLoginRequest request) async {
    final api = await _getApi();
    final data = (await api.mfaLogin(request.toJson())).data;
    if (data == null) return null;
    return LoginResponse.fromJson(data);
  }

  Future<void> logout() async {
    final api = await _getApi();
    await api.logout();
  }
}
