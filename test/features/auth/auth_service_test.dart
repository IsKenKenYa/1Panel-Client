import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/auth_models.dart';
import 'package:onepanel_client/features/auth/auth_repository.dart';
import 'package:onepanel_client/features/auth/auth_service.dart';
import 'package:onepanel_client/features/auth/auth_session_store.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class InMemoryAuthSessionStore implements AuthSessionStore {
  AuthSession? session;
  bool cleared = false;

  @override
  Future<void> clearSession() async {
    cleared = true;
    session = null;
  }

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> saveSession(AuthSession session) async {
    this.session = session;
  }
}

void main() {
  group('AuthService', () {
    late MockAuthRepository repository;
    late InMemoryAuthSessionStore sessionStore;
    late AuthService service;

    setUp(() {
      repository = MockAuthRepository();
      sessionStore = InMemoryAuthSessionStore();
      service = AuthService(
        repository: repository,
        sessionStore: sessionStore,
      );
    });

    test('restoreSession returns stored session', () async {
      sessionStore.session = const AuthSession(
        token: 'stored-token',
        username: 'admin',
      );

      final session = await service.restoreSession();

      expect(session?.token, 'stored-token');
      expect(session?.username, 'admin');
    });

    test('login persists session when token is returned', () async {
      when(
        () => repository.login(
          const LoginRequest(username: 'admin', password: 'password123'),
        ),
      ).thenAnswer(
        (_) async => const LoginResponse(
          token: 'auth-token',
          name: 'admin',
        ),
      );

      final response = await service.login(
        const LoginRequest(username: 'admin', password: 'password123'),
      );

      expect(response?.token, 'auth-token');
      expect(sessionStore.session?.token, 'auth-token');
      expect(sessionStore.session?.username, 'admin');
    });

    test('mfaLogin persists session for validated credentials', () async {
      when(
        () => repository.mfaLogin(
          const MfaLoginRequest(
            code: '123456',
            name: 'admin',
            password: 'password123',
          ),
        ),
      ).thenAnswer(
        (_) async => const LoginResponse(
          token: 'mfa-token',
          name: 'admin',
        ),
      );

      await service.mfaLogin(
        code: '123456',
        username: 'admin',
        password: 'password123',
      );

      expect(sessionStore.session?.token, 'mfa-token');
      expect(sessionStore.session?.username, 'admin');
    });

    test('logout clears stored session even when api logout throws', () async {
      sessionStore.session = const AuthSession(
        token: 'stored-token',
        username: 'admin',
      );
      when(() => repository.logout()).thenThrow(Exception('api failed'));

      await expectLater(service.logout(), throwsException);

      expect(sessionStore.cleared, isTrue);
      expect(sessionStore.session, isNull);
    });
  });
}
