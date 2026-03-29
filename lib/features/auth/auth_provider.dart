import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/passkey_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/auth_models.dart';
import 'package:onepanel_client/features/auth/auth_service.dart';

enum AuthStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  mfaRequired
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? service,
    PasskeyService? passkeyService,
  })  : _service = service ?? AuthService(),
        _passkeyService = passkeyService ?? PasskeyService();

  final AuthService _service;
  final PasskeyService _passkeyService;

  AuthStatus _status = AuthStatus.initial;
  String? _token;
  String? _username;
  String? _pendingPassword;
  String? _entranceCode;
  String? _errorMessage;
  CaptchaData? _captcha;
  LoginSettings? _loginSettings;
  bool _isPasskeySupported = false;
  String? _passkeyUnsupportedReason;
  bool _isPasskeyChecking = false;
  bool _isLoading = false;
  bool _isDemoMode = false;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get username => _username;
  String? get errorMessage => _errorMessage;
  CaptchaData? get captcha => _captcha;
  LoginSettings? get loginSettings => _loginSettings;
  bool get isPasskeySupported => _isPasskeySupported;
  String? get passkeyUnsupportedReason => _passkeyUnsupportedReason;
  bool get isPasskeyChecking => _isPasskeyChecking;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;

  Future<void> checkPasskeyAvailability() async {
    _isPasskeyChecking = true;
    notifyListeners();

    try {
      final availability = await _passkeyService.getAvailability();
      _isPasskeySupported = availability.isSupported;
      _passkeyUnsupportedReason = availability.reason;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'checkPasskeyAvailability failed',
        error: e,
        stackTrace: stackTrace,
      );
      _isPasskeySupported = false;
      _passkeyUnsupportedReason = _passkeyService.toUserMessage(e);
    }

    _isPasskeyChecking = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.checking;
    notifyListeners();

    try {
      final session = await _service.restoreSession();

      if (session != null) {
        _token = session.token;
        _username = session.username;
        _status = AuthStatus.authenticated;
      } else {
        _token = null;
        _username = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'checkAuthStatus failed',
        error: e,
        stackTrace: stackTrace,
      );
      _token = null;
      _username = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> loadLoginSettings() async {
    try {
      _loginSettings = await _service.loadLoginSettings();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'loadLoginSettings failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<void> loadCaptcha() async {
    try {
      _captcha = await _service.loadCaptcha();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'loadCaptcha failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<void> checkDemoMode() async {
    try {
      _isDemoMode = await _service.checkDemoMode();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'checkDemoMode failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
    String language = 'en',
    String? captcha,
    String? captchaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.login(
        LoginRequest(
          username: username,
          password: password,
          language: language,
          entranceCode: _entranceCode,
          captcha: captcha,
          captchaId: captchaId ?? _captcha?.captchaId,
        ),
      );

      if (response?.mfaStatus == true) {
        _username = username;
        _pendingPassword = password;
        _entranceCode = response?.entranceCode ?? _entranceCode;
        _status = AuthStatus.mfaRequired;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response?.token != null && response!.token!.isNotEmpty) {
        _token = response.token;
        _username = username;
        _pendingPassword = null;
        _entranceCode = response.entranceCode ?? _entranceCode;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response?.message ?? 'Login failed: Invalid response';
      _token = null;
      _pendingPassword = null;
      _status = AuthStatus.unauthenticated;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'login failed',
        error: e,
        stackTrace: stackTrace,
      );
      _token = null;
      _pendingPassword = null;
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> mfaLogin(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_username == null || _pendingPassword == null) {
        _errorMessage = 'MFA context is missing. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final response = await _service.mfaLogin(
        code: code,
        username: _username!,
        password: _pendingPassword!,
        entranceCode: _entranceCode,
      );

      if (response?.token != null && response!.token!.isNotEmpty) {
        _token = response.token;
        _username = _username ?? response.name;
        _pendingPassword = null;
        _entranceCode = response.entranceCode ?? _entranceCode;
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response?.message ?? 'MFA verification failed';
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'mfaLogin failed',
        error: e,
        stackTrace: stackTrace,
      );
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> passkeyLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final availability = await _passkeyService.getAvailability();
      _isPasskeySupported = availability.isSupported;
      _passkeyUnsupportedReason = availability.reason;

      if (!availability.isSupported) {
        _errorMessage = availability.reason ?? '当前平台不支持 Passkey';
        _status = AuthStatus.unauthenticated;
        return false;
      }

      final begin = await _service.beginPasskeyLogin(
        entranceCode: _entranceCode,
      );
      final sessionId = begin?.sessionId;
      final publicKey = begin?.publicKey;

      if (sessionId == null ||
          sessionId.isEmpty ||
          publicKey is! Map<String, dynamic>) {
        _errorMessage = 'Passkey 登录初始化失败';
        _status = AuthStatus.unauthenticated;
        return false;
      }

      final credential =
          await _passkeyService.authenticateCredential(publicKey);
      final response = await _service.finishPasskeyLogin(
        credential: credential,
        sessionId: sessionId,
        entranceCode: _entranceCode,
      );

      if (response?.token != null && response!.token!.isNotEmpty) {
        _token = response.token;
        _username = response.name;
        _pendingPassword = null;
        _entranceCode = response.entranceCode ?? _entranceCode;
        _status = AuthStatus.authenticated;
        return true;
      }

      _errorMessage = response?.message ?? 'Passkey 登录失败';
      _pendingPassword = null;
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'passkeyLogin failed',
        error: e,
        stackTrace: stackTrace,
      );
      _errorMessage = _passkeyService.toUserMessage(e);
      _pendingPassword = null;
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.logout();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'features.auth.auth_provider',
        'logout failed',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _token = null;
      _username = null;
      _pendingPassword = null;
      _entranceCode = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetMfaState() {
    _pendingPassword = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
