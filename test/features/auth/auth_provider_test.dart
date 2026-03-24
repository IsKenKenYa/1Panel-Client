import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onepanel_client/features/auth/auth_provider.dart';
import 'package:onepanel_client/data/models/auth_models.dart';

void main() {
  group('AuthModels', () {
    test('LoginRequest toJson should return correct map', () {
      final request = LoginRequest(
        username: 'admin',
        password: 'password123',
        captcha: '1234',
        captchaId: 'abc123',
      );

      final json = request.toJson();

      expect(json['name'], 'admin');
      expect(json['password'], 'password123');
      expect(json['captcha'], '1234');
      expect(json['captchaId'], 'abc123');
    });

    test('LoginRequest toJson without optional fields', () {
      final request = LoginRequest(
        username: 'admin',
        password: 'password123',
      );

      final json = request.toJson();

      expect(json['name'], 'admin');
      expect(json['password'], 'password123');
      expect(json.containsKey('captcha'), false);
      expect(json.containsKey('captchaId'), false);
    });

    test('LoginResponse fromJson should parse correctly', () {
      final json = {
        'token': 'test_token_123',
        'name': 'admin',
        'mfaStatus': false,
        'message': 'Login successful',
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, 'test_token_123');
      expect(response.name, 'admin');
      expect(response.mfaStatus, false);
      expect(response.message, 'Login successful');
    });

    test('LoginResponse with MFA status true', () {
      final json = {
        'token': null,
        'name': 'admin',
        'mfaStatus': true,
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, null);
      expect(response.mfaStatus, true);
    });

    test('CaptchaData fromJson should handle different key names', () {
      final json1 = {'captchaId': 'id1', 'imagePath': '/path/to/image'};
      final json2 = {'id': 'id2', 'path': '/path/to/image2'};
      final json3 = {'image': 'base64data', 'base64': 'base64data2'};

      final captcha1 = CaptchaData.fromJson(json1);
      final captcha2 = CaptchaData.fromJson(json2);
      final captcha3 = CaptchaData.fromJson(json3);

      expect(captcha1.captchaId, 'id1');
      expect(captcha2.captchaId, 'id2');
      expect(captcha3.base64, 'base64data');
    });

    test('LoginSettings fromJson should parse correctly', () {
      final json = {
        'captcha': true,
        'mfa': false,
        'demo': 'demo_mode',
        'title': '1Panel',
        'logo': '/logo.png',
      };

      final settings = LoginSettings.fromJson(json);

      expect(settings.captcha, true);
      expect(settings.mfa, false);
      expect(settings.demo, 'demo_mode');
      expect(settings.title, '1Panel');
    });

    test('MfaLoginRequest toJson should return correct map', () {
      final request = MfaLoginRequest(
        code: '123456',
        name: 'admin',
      );

      final json = request.toJson();

      expect(json['code'], '123456');
      expect(json['name'], 'admin');
    });

    test('SafetyStatus fromJson should handle different key names', () {
      final json1 = {'issafety': true, 'message': 'Safe'};
      final json2 = {'isSafety': false, 'message': 'Not Safe'};

      final status1 = SafetyStatus.fromJson(json1);
      final status2 = SafetyStatus.fromJson(json2);

      expect(status1.isSafety, true);
      expect(status2.isSafety, false);
    });

    test('DemoModeStatus fromJson should parse correctly', () {
      final json = {'demo': true, 'isDemo': false};

      final status = DemoModeStatus.fromJson(json);

      expect(status.isDemo, true);
    });

    test('Equatable works correctly for LoginRequest', () {
      final request1 = LoginRequest(username: 'admin', password: 'pass');
      final request2 = LoginRequest(username: 'admin', password: 'pass');
      final request3 = LoginRequest(username: 'user', password: 'pass');

      expect(request1 == request2, true);
      expect(request1 == request3, false);
    });
  });

  group('AuthProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial status should be initial', () {
      final provider = AuthProvider();
      expect(provider.status, AuthStatus.initial);
      expect(provider.isAuthenticated, false);
      expect(provider.isMfaRequired, false);
    });

    test('checkAuthStatus should set unauthenticated when no token', () async {
      final provider = AuthProvider();
      await provider.checkAuthStatus();

      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('checkAuthStatus should set authenticated when token exists', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token',
        'auth_username': 'admin',
      });

      final provider = AuthProvider();
      await provider.checkAuthStatus();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.token, 'test_token');
      expect(provider.username, 'admin');
    });

    test('Initial values should be null or false', () {
      final provider = AuthProvider();

      expect(provider.token, null);
      expect(provider.username, null);
      expect(provider.errorMessage, null);
      expect(provider.captcha, null);
      expect(provider.loginSettings, null);
      expect(provider.isLoading, false);
      expect(provider.isDemoMode, false);
    });
  });
}
