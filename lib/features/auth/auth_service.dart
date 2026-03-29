import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/auth_models.dart';
import 'package:onepanel_client/features/auth/auth_repository.dart';
import 'package:onepanel_client/features/auth/auth_session_store.dart';

class AuthService {
  AuthService({
    AuthRepository? repository,
    AuthSessionStore? sessionStore,
  })  : _repository = repository ?? AuthRepository(),
        _sessionStore = sessionStore ?? SecureAuthSessionStore();

  final AuthRepository _repository;
  final AuthSessionStore _sessionStore;

  Future<AuthSession?> restoreSession() async {
    appLogger.dWithPackage('features.auth.auth_service', 'restoreSession');
    return _sessionStore.readSession();
  }

  Future<LoginSettings?> loadLoginSettings() async {
    appLogger.dWithPackage('features.auth.auth_service', 'loadLoginSettings');
    return _repository.fetchLoginSettings();
  }

  Future<CaptchaData?> loadCaptcha() async {
    appLogger.dWithPackage('features.auth.auth_service', 'loadCaptcha');
    return _repository.fetchCaptcha();
  }

  Future<bool> checkDemoMode() async {
    appLogger.dWithPackage('features.auth.auth_service', 'checkDemoMode');
    final status = await _repository.fetchDemoModeStatus();
    return status?.isDemo ?? false;
  }

  Future<LoginResponse?> login(LoginRequest request) async {
    appLogger.dWithPackage(
      'features.auth.auth_service',
      'login: user=${request.username}',
    );
    final response = await _repository.login(request);
    await _persistSessionIfNeeded(
      response,
      username: request.username,
    );
    return response;
  }

  Future<LoginResponse?> mfaLogin({
    required String code,
    required String username,
    required String password,
    String? entranceCode,
  }) async {
    appLogger.dWithPackage(
      'features.auth.auth_service',
      'mfaLogin: user=$username',
    );
    final response = await _repository.mfaLogin(
      MfaLoginRequest(
        code: code,
        name: username,
        password: password,
        entranceCode: entranceCode,
      ),
    );
    await _persistSessionIfNeeded(
      response,
      username: username,
    );
    return response;
  }

  Future<PasskeyBeginResponse?> beginPasskeyLogin({
    String? entranceCode,
  }) async {
    appLogger.dWithPackage('features.auth.auth_service', 'beginPasskeyLogin');
    return _repository.beginPasskeyLogin(entranceCode: entranceCode);
  }

  Future<LoginResponse?> finishPasskeyLogin({
    required Map<String, dynamic> credential,
    required String sessionId,
    String? entranceCode,
  }) async {
    appLogger.dWithPackage('features.auth.auth_service', 'finishPasskeyLogin');
    final response = await _repository.finishPasskeyLogin(
      credential: credential,
      sessionId: sessionId,
      entranceCode: entranceCode,
    );
    await _persistSessionIfNeeded(
      response,
      username: response?.name,
    );
    return response;
  }

  Future<void> logout() async {
    appLogger.dWithPackage('features.auth.auth_service', 'logout');
    try {
      await _repository.logout();
    } finally {
      await _sessionStore.clearSession();
    }
  }

  Future<void> _persistSessionIfNeeded(
    LoginResponse? response, {
    String? username,
  }) async {
    final token = response?.token;
    if (token == null || token.isEmpty) return;

    await _sessionStore.saveSession(
      AuthSession(
        token: token,
        username: username,
      ),
    );
  }
}
