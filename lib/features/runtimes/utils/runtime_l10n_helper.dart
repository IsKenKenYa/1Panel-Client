import 'package:onepanel_client/l10n/generated/app_localizations.dart';

String runtimeTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'php' => l10n.runtimeTypePhp,
    'node' => l10n.runtimeTypeNode,
    'java' => l10n.runtimeTypeJava,
    'go' => l10n.runtimeTypeGo,
    'python' => l10n.runtimeTypePython,
    'dotnet' => l10n.runtimeTypeDotnet,
    _ => l10n.runtimeTypeUnknown(type),
  };
}

String runtimeResourceLabel(AppLocalizations l10n, String resource) {
  return switch (resource) {
    'local' => l10n.runtimeResourceLocal,
    'appstore' => l10n.runtimeResourceAppStore,
    _ => l10n.runtimeResourceUnknown(resource),
  };
}

String runtimeStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    '' => l10n.runtimeStatusAll,
    'Running' => l10n.runtimeStatusRunning,
    'Stopped' => l10n.runtimeStatusStopped,
    'Error' => l10n.runtimeStatusError,
    'Starting' => l10n.runtimeStatusStarting,
    'Building' => l10n.runtimeStatusBuilding,
    'Recreating' => l10n.runtimeStatusRecreating,
    'SystemRestart' => l10n.runtimeStatusSystemRestart,
    _ => l10n.runtimeStatusUnknown(status),
  };
}

String runtimeOperateLabel(AppLocalizations l10n, String operate) {
  return switch (operate) {
    'up' => l10n.runtimeActionStart,
    'down' => l10n.runtimeActionStop,
    'restart' => l10n.runtimeActionRestart,
    _ => l10n.runtimeActionUnknown(operate),
  };
}

String? localizeRuntimeError(
  AppLocalizations l10n,
  String? errorMessage,
) {
  return switch (errorMessage) {
    null || '' => null,
    'runtime.list.loadFailed' => l10n.runtimeListLoadFailed,
    'runtime.list.syncFailed' => l10n.runtimeSyncFailed,
    'runtime.list.deleteFailed' => l10n.runtimeDeleteFailed,
    'runtime.list.operateFailed' => l10n.runtimeOperateFailed,
    'runtime.detail.loadFailed' => l10n.runtimeDetailLoadFailed,
    'runtime.detail.operateFailed' => l10n.runtimeOperateFailed,
    'runtime.nodeScript.waitTimeout' => l10n.runtimeNodeScriptWaitTimeout,
    'runtime.detail.remarkFailed' => l10n.runtimeRemarkSaveFailed,
    'runtime.detail.syncFailed' => l10n.runtimeSyncFailed,
    'runtime.form.loadFailed' => l10n.runtimeFormLoadFailed,
    'runtime.form.saveFailed' => l10n.runtimeFormSaveFailed,
    'runtime.form.nameRequired' => l10n.runtimeFormNameRequired,
    'runtime.form.imageRequired' => l10n.runtimeFormImageRequired,
    'runtime.form.codeDirRequired' => l10n.runtimeFormCodeDirRequired,
    'runtime.form.portInvalid' => l10n.runtimeFormPortInvalid,
    'runtime.form.containerRequired' => l10n.runtimeFormContainerNameRequired,
    'runtime.form.execScriptRequired' => l10n.runtimeFormExecScriptRequired,
    'runtime.form.packageManagerRequired' =>
      l10n.runtimeFormPackageManagerRequired,
    'runtime.form.week8AppStoreCreate' =>
      l10n.runtimeFormAppStoreCreateWeek8Hint,
    'runtime.form.week8PhpCreate' => l10n.runtimeFormPhpCreateWeek8Hint,
    'runtime.remark.tooLong' => l10n.runtimeRemarkTooLong,
    _ => errorMessage,
  };
}
