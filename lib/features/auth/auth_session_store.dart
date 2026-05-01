import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    this.username,
  });

  final String token;
  final String? username;
}

abstract class AuthSessionStore {
  Future<AuthSession?> readSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
}

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String tokenKey = 'auth_token';
  static const String usernameKey = 'auth_username';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> readSession() async {
    final token = await _storage.read(key: tokenKey);
    if (token == null || token.isEmpty) return null;

    return AuthSession(
      token: token,
      username: await _storage.read(key: usernameKey),
    );
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: tokenKey, value: session.token);
    if (session.username == null || session.username!.isEmpty) {
      await _storage.delete(key: usernameKey);
      return;
    }
    await _storage.write(key: usernameKey, value: session.username);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: usernameKey);
  }
}
