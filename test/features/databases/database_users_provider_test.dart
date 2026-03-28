import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/providers/database_users_provider.dart';
import 'package:onepanel_client/features/databases/services/database_user_service.dart';

class _FakeDatabaseUserService extends DatabaseUserService {
  _FakeDatabaseUserService({
    required this.context,
    this.throwOnBind = false,
    this.throwOnPrivilege = false,
  });

  final DatabaseUserContext context;
  final bool throwOnBind;
  final bool throwOnPrivilege;

  int bindCallCount = 0;
  int privilegeCallCount = 0;

  @override
  Future<DatabaseUserContext> loadContext(DatabaseListItem item) async =>
      context;

  @override
  Future<void> bindUser(
    DatabaseListItem item, {
    required String username,
    required String password,
    String permission = '%',
    bool superUser = false,
  }) async {
    bindCallCount += 1;
    if (throwOnBind) {
      throw Exception('bind failed');
    }
  }

  @override
  Future<void> updatePrivileges(
    DatabaseListItem item, {
    required String username,
    required bool superUser,
  }) async {
    privilegeCallCount += 1;
    if (throwOnPrivilege) {
      throw Exception('privilege failed');
    }
  }
}

void main() {
  const pgItem = DatabaseListItem(
    scope: DatabaseScope.postgresql,
    name: 'app_db',
    engine: 'pg-main',
    source: 'local',
    username: 'db_user',
  );

  test('DatabaseUsersProvider bindUser updates current username', () async {
    final service = _FakeDatabaseUserService(
      context: const DatabaseUserContext(
        supportsBinding: true,
        supportsPrivileges: true,
      ),
    );
    final provider = DatabaseUsersProvider(item: pgItem, service: service);

    await provider.load();
    final ok = await provider.bindUser(
      username: 'next_user',
      password: 'secret',
      superUser: true,
    );

    expect(ok, isTrue);
    expect(service.bindCallCount, 1);
    expect(provider.state.context?.currentUsername, 'next_user');
    expect(provider.state.context?.superUser, isTrue);
  });

  test('DatabaseUsersProvider updatePrivileges reports failures', () async {
    final service = _FakeDatabaseUserService(
      context: const DatabaseUserContext(
        supportsBinding: true,
        supportsPrivileges: true,
        currentUsername: 'db_user',
      ),
      throwOnPrivilege: true,
    );
    final provider = DatabaseUsersProvider(item: pgItem, service: service);

    await provider.load();
    final ok = await provider.updatePrivileges(superUser: false);

    expect(ok, isFalse);
    expect(service.privilegeCallCount, 1);
    expect(provider.state.error, contains('privilege failed'));
  });

  test('DatabaseUsersProvider bindUser reports failures', () async {
    final service = _FakeDatabaseUserService(
      context: const DatabaseUserContext(
        supportsBinding: true,
        supportsPrivileges: true,
      ),
      throwOnBind: true,
    );
    final provider = DatabaseUsersProvider(item: pgItem, service: service);

    await provider.load();
    final ok = await provider.bindUser(
      username: 'next_user',
      password: 'secret',
    );

    expect(ok, isFalse);
    expect(service.bindCallCount, 1);
    expect(provider.state.error, contains('bind failed'));
  });
}
