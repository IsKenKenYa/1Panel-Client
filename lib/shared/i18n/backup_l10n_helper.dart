import 'package:onepanel_client/l10n/generated/app_localizations.dart';

String backupProviderLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'LOCAL' => l10n.backupTypeLocal,
    'SFTP' => l10n.backupTypeSftp,
    'WebDAV' => l10n.backupTypeWebdav,
    'S3' => l10n.backupTypeS3,
    'MINIO' => l10n.backupTypeMinio,
    'OSS' => l10n.backupTypeOss,
    'COS' => l10n.backupTypeCos,
    'KODO' => l10n.backupTypeKodo,
    'UPYUN' => l10n.backupTypeUpyun,
    'OneDrive' => l10n.backupTypeOneDrive,
    'GoogleDrive' => l10n.backupTypeGoogleDrive,
    'ALIYUN' => l10n.backupTypeAliyun,
    _ => type,
  };
}

String backupResourceTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'app' => l10n.backupTypeApp,
    'website' => l10n.backupTypeWebsite,
    'database' => l10n.backupTypeDatabase,
    'directory' => l10n.backupTypeDirectory,
    'snapshot' => l10n.backupTypeSnapshot,
    'log' => l10n.backupTypeLog,
    'container' => l10n.backupTypeContainer,
    'compose' => l10n.backupTypeCompose,
    'other' => l10n.backupTypeOther,
    'mysql' => l10n.databaseTypeMysql,
    'mysql-cluster' => l10n.databaseTypeMysqlCluster,
    'mariadb' => l10n.databaseTypeMariadb,
    'postgresql' => l10n.databaseTypePostgresql,
    'postgresql-cluster' => l10n.databaseTypePostgresqlCluster,
    'redis' => l10n.databaseTypeRedis,
    'redis-cluster' => l10n.databaseTypeRedis,
    _ => l10n.backupResourceTypeUnknownLabel(type),
  };
}

String? localizeBackupError(AppLocalizations l10n, String? errorMessage) {
  return switch (errorMessage) {
    null || '' => null,
    'backup.oauthOpenFailed' ||
    'Could not open authorize page' =>
      l10n.backupErrorOauthOpenFailed,
    'backup.oauthUnsupportedProvider' =>
      l10n.backupErrorOauthUnsupportedProvider,
    'backup.recordPathEmpty' ||
    'Backup record path is empty' =>
      l10n.backupErrorRecordPathEmpty,
    'backup.recordDownloadEmpty' ||
    'Downloaded backup record is empty' =>
      l10n.backupErrorRecordDownloadEmpty,
    _ => errorMessage,
  };
}
