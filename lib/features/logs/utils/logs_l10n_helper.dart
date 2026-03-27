import 'package:onepanel_client/l10n/generated/app_localizations.dart';

String? localizeLogsError(
  AppLocalizations l10n,
  String? errorMessage,
) {
  switch (errorMessage) {
    case null:
    case '':
      return null;
    case 'logs.operation.loadFailed':
      return l10n.logsOperationLoadFailed;
    case 'logs.login.loadFailed':
      return l10n.logsLoginLoadFailed;
    case 'logs.task.loadFailed':
      return l10n.logsTaskLoadFailed;
    case 'logs.task.detailLoadFailed':
      return l10n.logsTaskDetailLoadFailed;
    case 'logs.task.missingTaskId':
      return l10n.logsTaskMissingTaskId;
    case 'logs.system.filesLoadFailed':
      return l10n.logsSystemFilesLoadFailed;
    case 'logs.system.contentLoadFailed':
      return l10n.logsSystemContentLoadFailed;
    default:
      return errorMessage;
  }
}
