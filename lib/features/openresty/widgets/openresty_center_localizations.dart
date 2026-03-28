import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';

String openRestyStatusSummary(
    BuildContext context, OpenRestyProvider provider) {
  final l10n = context.l10n;
  if (!provider.isRunning) {
    return l10n.openrestyStatusNotRunningSummary;
  }
  final active = (provider.status?['active'] as num?)?.toInt() ?? 0;
  return l10n.openrestyStatusRunningSummary(active);
}

String openRestyHttpsSummary(BuildContext context, OpenRestyProvider provider) {
  final l10n = context.l10n;
  return provider.httpsEnabled
      ? l10n.openrestyHttpsEnabledSummary
      : l10n.openrestyHttpsDisabledSummary;
}

String openRestyModulesSummary(
  BuildContext context,
  OpenRestyProvider provider,
) {
  final l10n = context.l10n;
  final enabled =
      provider.moduleList.where((module) => module.enable == true).length;
  return l10n.openrestyModulesEnabledSummary(
      enabled, provider.moduleList.length);
}

String openRestyBuildSummary(BuildContext context, OpenRestyProvider provider) {
  final l10n = context.l10n;
  final mirror = provider.modules?['mirror']?.toString() ?? '';
  final normalized = mirror.trim();
  if (normalized.isEmpty) {
    return l10n.openrestyBuildNoMirrorConfigured;
  }
  return normalized;
}

String openRestyConfigSummary(
    BuildContext context, OpenRestyProvider provider) {
  final l10n = context.l10n;
  final content = provider.configContent.trim();
  if (content.isEmpty) {
    return l10n.openrestyConfigNotLoaded;
  }
  return l10n.openrestyConfigLoadedSummary(content.split('\n').length);
}

List<ConfigDiffItem> localizeOpenRestyDiffItems(
  BuildContext context,
  List<ConfigDiffItem> items,
) {
  final l10n = context.l10n;
  return items.map((item) {
    return ConfigDiffItem(
      field: item.field,
      label: _localizeOpenRestyDiffLabel(l10n, item.label),
      currentValue: _localizeOpenRestyDiffValue(l10n, item.currentValue),
      nextValue: _localizeOpenRestyDiffValue(l10n, item.nextValue),
    );
  }).toList(growable: false);
}

List<RiskNotice> localizeOpenRestyRiskNotices(
  BuildContext context,
  List<RiskNotice> notices,
) {
  final l10n = context.l10n;
  return notices.map((notice) {
    switch (notice.title) {
      case 'Gateway inactive':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskGatewayInactiveTitle,
          message: l10n.openrestyRiskGatewayInactiveMessage,
        );
      case 'HTTPS disabled':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskHttpsDisabledTitle,
          message: l10n.openrestyRiskHttpsDisabledMessage,
        );
      case 'No modules loaded':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskNoModulesTitle,
          message: l10n.openrestyRiskNoModulesMessage,
        );
      case 'Build mirror missing':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskBuildMirrorMissingTitle,
          message: l10n.openrestyRiskBuildMirrorMissingMessage,
        );
      case 'Reject handshake enabled':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskRejectHandshakeTitle,
          message: l10n.openrestyRiskRejectHandshakeMessage,
        );
      case 'Module disabled':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskModuleDisabledTitle,
          message: l10n.openrestyRiskModuleDisabledMessage(
            _extractModuleName(
              notice.message,
              pattern: RegExp(
                  r'Disabling (.+) may change gateway behavior immediately\\.'),
            ),
          ),
        );
      case 'Dependency change':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskDependencyChangeTitle,
          message: l10n.openrestyRiskDependencyChangeMessage(
            _extractModuleName(
              notice.message,
              pattern: RegExp(
                  r'Package or script changes can introduce dependency conflicts for (.+)\\.'),
            ),
          ),
        );
      case 'Empty config':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskEmptyConfigTitle,
          message: l10n.openrestyRiskEmptyConfigMessage,
        );
      case 'Brace mismatch':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskBraceMismatchTitle,
          message: l10n.openrestyRiskBraceMismatchMessage,
        );
      case 'Missing http block':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskMissingHttpBlockTitle,
          message: l10n.openrestyRiskMissingHttpBlockMessage,
        );
      case 'Temporary markers found':
        return RiskNotice(
          level: notice.level,
          title: l10n.openrestyRiskTemporaryMarkersTitle,
          message: l10n.openrestyRiskTemporaryMarkersMessage,
        );
      default:
        return notice;
    }
  }).toList(growable: false);
}

String _extractModuleName(
  String source, {
  required RegExp pattern,
}) {
  final match = pattern.firstMatch(source);
  final module = match?.group(1)?.trim();
  if (module == null || module.isEmpty) {
    return '-';
  }
  return module;
}

String _localizeOpenRestyDiffLabel(AppLocalizations l10n, String label) {
  switch (label) {
    case 'HTTPS':
      return l10n.openrestyDiffLabelHttps;
    case 'Reject Handshake':
      return l10n.openrestyDiffLabelRejectHandshake;
    case 'Enabled':
      return l10n.openrestyDiffLabelEnabled;
    case 'Packages':
      return l10n.openrestyDiffLabelPackages;
    case 'Params':
      return l10n.openrestyDiffLabelParams;
    case 'Script':
      return l10n.openrestyDiffLabelScript;
    case 'Config Source':
      return l10n.openrestyDiffLabelConfigSource;
    default:
      return label;
  }
}

String _localizeOpenRestyDiffValue(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Enabled':
      return l10n.systemSettingsEnabled;
    case 'Disabled':
      return l10n.systemSettingsDisabled;
    default:
      return value;
  }
}
