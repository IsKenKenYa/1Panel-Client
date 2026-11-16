import 'package:onepanel_client/l10n/generated/app_localizations.dart';

/// 容器状态（Docker state）到用户文案的统一映射。
///
/// 列表卡片与详情页共用，避免详情页直接展示上游英文状态串
/// （如 "Restarting (1) 32 hours ago"）。
String containerStatusLabel(AppLocalizations l10n, String state) {
  switch (state.toLowerCase()) {
    case 'running':
      return l10n.containerStatusRunning;
    case 'paused':
      return l10n.containerStatusPaused;
    case 'exited':
    case 'stopped':
      return l10n.containerStatusStopped;
    case 'restarting':
      return l10n.containerStatusRestarting;
    case 'removing':
      return l10n.containerStatusRemoving;
    case 'dead':
      return l10n.containerStatusDead;
    case 'created':
      return l10n.containerStatusCreated;
    default:
      return state;
  }
}