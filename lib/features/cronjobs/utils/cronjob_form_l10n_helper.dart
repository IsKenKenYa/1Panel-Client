import 'package:onepanel_client/l10n/generated/app_localizations.dart';

String cronjobBackupTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'app':
      return l10n.backupTypeApp;
    case 'website':
      return l10n.backupTypeWebsite;
    case 'database':
      return l10n.backupTypeDatabase;
    case 'directory':
      return l10n.backupTypeDirectory;
    case 'snapshot':
      return l10n.backupTypeSnapshot;
    case 'log':
      return l10n.backupTypeLog;
    default:
      return l10n.cronjobFormUnknownBackupType(type);
  }
}

String cronjobDatabaseTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'mysql':
      return l10n.databaseTypeMysql;
    case 'mysql-cluster':
      return l10n.databaseTypeMysqlCluster;
    case 'mariadb':
      return l10n.databaseTypeMariadb;
    case 'postgresql':
      return l10n.databaseTypePostgresql;
    case 'postgresql-cluster':
      return l10n.databaseTypePostgresqlCluster;
    case 'redis':
      return l10n.databaseTypeRedis;
    default:
      return l10n.cronjobFormUnknownDatabaseType(type);
  }
}

String cronjobAlertMethodLabel(AppLocalizations l10n, String method) {
  switch (method) {
    case 'mail':
      return l10n.cronjobFormAlertMethodMail;
    case 'weCom':
      return l10n.cronjobFormAlertMethodWecom;
    case 'dingTalk':
      return l10n.cronjobFormAlertMethodDingtalk;
    default:
      return l10n.cronjobFormUnknownAlertMethod(method);
  }
}

String? localizeCronjobFormError(
  AppLocalizations l10n,
  String? errorMessage,
) {
  switch (errorMessage) {
    case null:
    case '':
      return null;
    case 'cronjob.importInvalidJson':
    case 'Cronjob import file must be a JSON array':
      return l10n.cronjobFormImportInvalidJson;
    case 'cronjob.exportEmpty':
    case 'Exported cronjob file is empty':
      return l10n.cronjobFormExportEmpty;
    case 'cronjob.specRequired':
    case 'Cronjob spec is required':
      return l10n.cronjobFormSpecRequired;
    case 'cronjob.unsupportedType':
      return l10n.cronjobFormUnsupportedType;
    default:
      return l10n.cronjobFormUnknownError(errorMessage);
  }
}
