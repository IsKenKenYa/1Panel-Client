import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/services/passkey_service.dart';
import 'package:onepanel_client/data/models/auth_models.dart';
import 'package:onepanel_client/features/auth/auth_provider.dart';
import 'package:onepanel_client/features/auth/auth_service.dart';
import 'package:onepanel_client/features/auth/auth_session_store.dart';

class MockAuthService extends Mock implements AuthService {}

class MockPasskeyService extends Mock implements PasskeyService {}

void main() {
  group('AuthModels', () {
    test('LoginRequest toJson should return correct map', () {
      const request = LoginRequest(
        username: 'admin',
        password: 'password123',
        captcha: '1234',
        captchaId: 'abc123',
      );

      final json = request.toJson();

      expect(json['name'], 'admin');
      expect(json['password'], 'password123');
      expect(json['language'], 'en');
      expect(json['captcha'], '1234');
      expect(json['captchaID'], 'abc123');
    });

    test('LoginRequest toJson without optional fields', () {
      const request = LoginRequest(
        username: 'admin',
        password: 'password123',
      );

      final json = request.toJson();

      expect(json['name'], 'admin');
      expect(json['password'], 'password123');
      expect(json['language'], 'en');
      expect(json.containsKey('captcha'), false);
      expect(json.containsKey('captchaID'), false);
    });

    test('LoginResponse fromJson should parse correctly', () {
      final response = LoginResponse.fromJson({
        'token': 'test_token_123',
        'name': 'admin',
        'mfaStatus': false,
        'message': 'Login successful',
      });

      expect(response.token, 'test_token_123');
      expect(response.name, 'admin');
      expect(response.mfaStatus, false);
      expect(response.message, 'Login successful');
    });

    test('LoginResponse with MFA status true', () {
      final response = LoginResponse.fromJson({
        'token': null,
        'name': 'admin',
        'mfaStatus': true,
      });

      expect(response.token, null);
      expect(response.mfaStatus, true);
    });

    test('LoginResponse parses string MFA status from swagger schema', () {
      final response = LoginResponse.fromJson({
        'token': null,
        'name': 'admin',
        'mfaStatus': 'enable',
      });

      expect(response.mfaStatus, true);
    });

    test('CaptchaData fromJson should handle different key names', () {
      final captcha1 = CaptchaData.fromJson({
        'captchaId': 'id1',
        'imagePath': '/path/to/image',
      });
      final captcha2 = CaptchaData.fromJson({
        'id': 'id2',
        'path': '/path/to/image2',
      });
      final captcha3 = CaptchaData.fromJson({
        'image': 'base64data',
        'base64': 'base64data2',
      });

      expect(captcha1.captchaId, 'id1');
      expect(captcha2.captchaId, 'id2');
      expect(captcha3.base64, 'base64data');
    });

    test('LoginSettings fromJson should parse correctly', () {
      final settings = LoginSettings.fromJson({
        'captcha': true,
        'mfa': false,
        'demo': 'demo_mode',
        'title': '1Panel',
        'logo': '/logo.png',
      });

      expect(settings.captcha, true);
      expect(settings.mfa, false);
      expect(settings.demo, 'demo_mode');
      expect(settings.title, '1Panel');
    });

    test('MfaLoginRequest toJson should return correct map', () {
      const request = MfaLoginRequest(
        code: '123456',
        name: 'admin',
        password: 'password123',
      );

      final json = request.toJson();

      expect(json['code'], '123456');
      expect(json['name'], 'admin');
      expect(json['password'], 'password123');
    });

    test('SafetyStatus fromJson should handle different key names', () {
      final status1 = SafetyStatus.fromJson({
        'issafety': true,
        'message': 'Safe',
      });
      final status2 = SafetyStatus.fromJson({
        'isSafety': false,
        'message': 'Not Safe',
      });

      expect(status1.isSafety, true);
      expect(status2.isSafety, false);
    });

    test('DemoModeStatus fromJson should parse correctly', () {
      final status = DemoModeStatus.fromJson({
        'demo': true,
        'isDemo': false,
      });

      expect(status.isDemo, true);
    });

    test('Equatable works correctly for LoginRequest', () {
      const request1 = LoginRequest(username: 'admin', password: 'pass');
      const request2 = LoginRequest(username: 'admin', password: 'pass');
      const request3 = LoginRequest(username: 'user', password: 'pass');

      expect(request1 == request2, true);
      expect(request1 == request3, false);
    });
  });

  group('AuthProvider', () {
    late MockAuthService service;
    late MockPasskeyService passkeyService;
    late AuthProvider provider;

    setUpAll(() {
      registerFallbackValue(
        const LoginRequest(username: 'fallback', password: 'fallback'),
      );
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      service = MockAuthService();
      passkeyService = MockPasskeyService();
      provider = AuthProvider(
        service: service,
        passkeyService: passkeyService,
      );
    });

    test('Initial status should be initial', () {
      expect(provider.status, AuthStatus.initial);
      expect(provider.isAuthenticated, false);
      expect(provider.isMfaRequired, false);
    });

    test('checkAuthStatus should set unauthenticated when no session',
        () async {
      when(() => service.restoreSession()).thenAnswer((_) async => null);

      await provider.checkAuthStatus();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.token, isNull);
    });

    test('checkAuthStatus should set authenticated when session exists',
        () async {
      when(
        () => service.restoreSession(),
      ).thenAnswer(
        (_) async => const AuthSession(
          token: 'test_token',
          username: 'admin',
        ),
      );

      await provider.checkAuthStatus();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.token, 'test_token');
      expect(provider.username, 'admin');
    });

    test('loadLoginSettings should store fetched settings', () async {
      when(
        () => service.loadLoginSettings(),
      ).thenAnswer(
        (_) async => const LoginSettings(captcha: true, title: '1Panel'),
      );

      await provider.loadLoginSettings();

      expect(provider.loginSettings?.captcha, true);
      expect(provider.loginSettings?.title, '1Panel');
    });

    test('login should authenticate when service returns token', () async {
      when(
        () => service.login(any()),
      ).thenAnswer(
        (_) async => const LoginResponse(
          token: 'auth-token',
          name: 'admin',
        ),
      );

      final success = await provider.login(
        username: 'admin',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.token, 'auth-token');
      expect(provider.username, 'admin');
    });

    test('login should enter mfaRequired when service requests MFA', () async {
      when(
        () => service.login(any()),
      ).thenAnswer(
        (_) async => const LoginResponse(
          mfaStatus: true,
          name: 'admin',
        ),
      );

      final success = await provider.login(
        username: 'admin',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(provider.status, AuthStatus.mfaRequired);
      expect(provider.username, 'admin');
    });

    test('mfaLogin should authenticate when service returns token', () async {
      when(() => service.login(any())).thenAnswer(
        (_) async => const LoginResponse(mfaStatus: true),
      );
      when(
        () => service.mfaLogin(
          code: '123456',
          username: 'admin',
          password: 'password123',
          entranceCode: any(named: 'entranceCode'),
        ),
      ).thenAnswer(
        (_) async => const LoginResponse(
          token: 'mfa-token',
          name: 'admin',
        ),
      );

      await provider.login(username: 'admin', password: 'password123');
      final success = await provider.mfaLogin('123456');

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.token, 'mfa-token');
    });

    test('checkPasskeyAvailability should update support status', () async {
      when(
        () => passkeyService.getAvailability(),
      ).thenAnswer((_) async => const PasskeyAvailabilityResult.supported());

      await provider.checkPasskeyAvailability();

      expect(provider.isPasskeySupported, isTrue);
      expect(provider.passkeyUnsupportedReason, isNull);
      expect(provider.isPasskeyChecking, isFalse);
    });

    test('passkeyLogin should authenticate when passkey flow succeeds',
        () async {
      const sessionId = 'session-1';
      final credential = <String, dynamic>{'id': 'credential-1'};

      when(
        () => passkeyService.getAvailability(),
      ).thenAnswer((_) async => const PasskeyAvailabilityResult.supported());
      when(
        () => service.beginPasskeyLogin(
          entranceCode: any(named: 'entranceCode'),
        ),
      ).thenAnswer(
        (_) async => const PasskeyBeginResponse(
          sessionId: sessionId,
          publicKey: {'challenge': 'abc'},
        ),
      );
      when(
        () => passkeyService.authenticateCredential(any()),
      ).thenAnswer((_) async => credential);
      when(
        () => service.finishPasskeyLogin(
          credential: credential,
          sessionId: sessionId,
          entranceCode: any(named: 'entranceCode'),
        ),
      ).thenAnswer(
        (_) async => const LoginResponse(
          token: 'passkey-token',
          name: 'admin',
        ),
      );

      final success = await provider.passkeyLogin();

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.token, 'passkey-token');
      expect(provider.username, 'admin');
    });

    test('passkeyLogin should fail when platform unsupported', () async {
      when(
        () => passkeyService.getAvailability(),
      ).thenAnswer(
        (_) async =>
            const PasskeyAvailabilityResult.unsupported('Linux 仅提供占位提示'),
      );

      final success = await provider.passkeyLogin();

      expect(success, isFalse);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, contains('Linux'));
    });

    test('logout should clear session state even when service fails', () async {
      when(
        () => service.restoreSession(),
      ).thenAnswer(
        (_) async => const AuthSession(
          token: 'test_token',
          username: 'admin',
        ),
      );
      when(() => service.logout()).thenThrow(Exception('network error'));

      await provider.checkAuthStatus();
      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.token, isNull);
      expect(provider.username, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('Initial values should be null or false', () {
      expect(provider.token, isNull);
      expect(provider.username, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.captcha, isNull);
      expect(provider.loginSettings, isNull);
      expect(provider.isPasskeySupported, false);
      expect(provider.isLoading, false);
      expect(provider.isDemoMode, false);
    });
  });
}
