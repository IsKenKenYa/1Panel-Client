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
    return (await api.getCaptcha()).data;
  }

  Future<DemoModeStatus?> fetchDemoModeStatus() async {
    final api = await _getApi();
    final data = (await api.checkDemoMode()).data;
    if (data == null) return null;
    return DemoModeStatus.fromJson(data);
  }

  Future<LoginResponse?> login(LoginRequest request) async {
    final api = await _getApi();
    final response = await api.login(
      request.toJson(),
      entranceCode: request.entranceCode,
    );
    final data = response.data;
    if (data == null) return null;
    final entranceCode = response.headers.value('EntranceCode') ??
        response.headers.value('entrancecode');
    return LoginResponse.fromJson(data).copyWith(entranceCode: entranceCode);
  }

  Future<LoginResponse?> mfaLogin(MfaLoginRequest request) async {
    final api = await _getApi();
    final response = await api.mfaLogin(
      request.toJson(),
      entranceCode: request.entranceCode,
    );
    final data = response.data;
    if (data == null) return null;
    final entranceCode = response.headers.value('EntranceCode') ??
        response.headers.value('entrancecode');
    return LoginResponse.fromJson(data).copyWith(entranceCode: entranceCode);
  }

  Future<PasskeyBeginResponse?> beginPasskeyLogin({
    String? entranceCode,
  }) async {
    final api = await _getApi();
    final response = await api.passkeyBeginLogin(entranceCode: entranceCode);
    return response.data;
  }

  Future<LoginResponse?> finishPasskeyLogin({
    required Map<String, dynamic> credential,
    required String sessionId,
    String? entranceCode,
  }) async {
    final api = await _getApi();
    final response = await api.passkeyFinishLogin(
      credential: credential,
      sessionId: sessionId,
      entranceCode: entranceCode,
    );
    final data = response.data;
    if (data == null) return null;
    final nextEntranceCode = response.headers.value('EntranceCode') ??
        response.headers.value('entrancecode');
    return LoginResponse.fromJson(data)
        .copyWith(entranceCode: nextEntranceCode);
  }

  Future<void> logout() async {
    final api = await _getApi();
    await api.logout();
  }
}
