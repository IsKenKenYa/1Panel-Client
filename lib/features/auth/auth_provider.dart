import 'package:flutter/material.dart';
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
  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  AuthStatus _status = AuthStatus.initial;
  String? _token;
  String? _username;
  String? _pendingPassword;
  String? _entranceCode;
  String? _errorMessage;
  CaptchaData? _captcha;
  LoginSettings? _loginSettings;
  bool _isLoading = false;
  bool _isDemoMode = false;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get username => _username;
  String? get errorMessage => _errorMessage;
  CaptchaData? get captcha => _captcha;
  LoginSettings? get loginSettings => _loginSettings;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _isDemoMode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;

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
