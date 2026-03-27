import 'package:onepanel_client/data/models/database_models.dart';

bool databaseSupportsBackups(DatabaseScope scope) {
  return scope == DatabaseScope.mysql ||
      scope == DatabaseScope.postgresql ||
      scope == DatabaseScope.redis;
}

bool databaseSupportsUserManagement(DatabaseScope scope) {
  return scope == DatabaseScope.mysql || scope == DatabaseScope.postgresql;
}

bool databaseSupportsPrivilegeManagement(DatabaseScope scope) {
  return scope == DatabaseScope.postgresql;
}

String databaseBackupType(DatabaseListItem item) {
  switch (item.scope) {
    case DatabaseScope.mysql:
      return 'mysql';
    case DatabaseScope.postgresql:
      return 'postgresql';
    case DatabaseScope.redis:
      return 'redis';
    case DatabaseScope.remote:
      throw UnsupportedError('Remote databases do not support backups.');
  }
}

String databaseBackupName(DatabaseListItem item) {
  switch (item.scope) {
    case DatabaseScope.mysql:
    case DatabaseScope.postgresql:
      return item.engine;
    case DatabaseScope.redis:
      return item.lookupName;
    case DatabaseScope.remote:
      throw UnsupportedError('Remote databases do not support backups.');
  }
}

String databaseBackupDetailName(DatabaseListItem item) {
  switch (item.scope) {
    case DatabaseScope.mysql:
    case DatabaseScope.postgresql:
      return item.name;
    case DatabaseScope.redis:
      return '';
    case DatabaseScope.remote:
      throw UnsupportedError('Remote databases do not support backups.');
  }
}
