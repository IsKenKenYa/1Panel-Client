import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/repositories/database_user_repository.dart';
import 'package:onepanel_client/features/databases/database_support.dart';

class DatabaseUserContext {
  const DatabaseUserContext({
    required this.supportsBinding,
    required this.supportsPrivileges,
    this.currentUsername,
    this.superUser = false,
  });

  final bool supportsBinding;
  final bool supportsPrivileges;
  final String? currentUsername;
  final bool superUser;

  DatabaseUserContext copyWith({
    bool? supportsBinding,
    bool? supportsPrivileges,
    String? currentUsername,
    bool? superUser,
  }) {
    return DatabaseUserContext(
      supportsBinding: supportsBinding ?? this.supportsBinding,
      supportsPrivileges: supportsPrivileges ?? this.supportsPrivileges,
      currentUsername: currentUsername ?? this.currentUsername,
      superUser: superUser ?? this.superUser,
    );
  }
}

class DatabaseUserService {
  DatabaseUserService({DatabaseUserRepository? repository})
      : _repository = repository ?? DatabaseUserRepository();

  final DatabaseUserRepository _repository;

  Future<DatabaseUserContext> loadContext(DatabaseListItem item) async {
    return DatabaseUserContext(
      supportsBinding: databaseSupportsUserManagement(item.scope),
      supportsPrivileges: databaseSupportsPrivilegeManagement(item.scope),
      currentUsername: item.username,
    );
  }

  Future<void> bindUser(
    DatabaseListItem item, {
    required String username,
    required String password,
    String permission = '%',
    bool superUser = false,
  }) async {
    if (item.scope == DatabaseScope.postgresql) {
      await _repository.bindPostgresqlUser(
        item,
        username: username,
        password: password,
        superUser: superUser,
      );
      return;
    }
    await _repository.bindMysqlUser(
      item,
      username: username,
      password: password,
      permission: permission,
    );
  }

  Future<void> updatePrivileges(
    DatabaseListItem item, {
    required String username,
    required bool superUser,
  }) {
    return _repository.updatePostgresqlPrivileges(
      item,
      username: username,
      superUser: superUser,
    );
  }
}
