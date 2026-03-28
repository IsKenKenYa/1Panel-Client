import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/openresty/widgets/openresty_center_dialogs.dart';
import 'package:onepanel_client/features/openresty/widgets/openresty_center_localizations.dart';
import 'package:onepanel_client/features/openresty/widgets/openresty_center_section_widgets.dart';
import 'package:onepanel_client/features/openresty/widgets/openresty_error_view.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/config_diff_preview_card.dart';
import 'package:onepanel_client/shared/security_gateway/widgets/risk_notice_banner.dart';
import 'package:provider/provider.dart';

class OpenRestyCenterPage extends StatelessWidget {
  const OpenRestyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OpenRestyProvider>(
      builder: (context, provider, _) {
        final l10n = context.l10n;
        if (provider.error != null && !provider.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.openrestyPageTitle)),
            body: OpenRestyErrorView(
              message: provider.error!,
              onRetry: provider.loadAll,
            ),
          );
        }

        if (provider.isLoading && !provider.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.openrestyPageTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.l10n.commonRefresh,
                onPressed: provider.refresh,
              ),
              IconButton(
                icon: const Icon(Icons.code),
                tooltip: l10n.openrestyAdvancedSourceEditorTooltip,
                onPressed: () => _openSourceEditor(context, provider),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
            children: [
              if (provider.isLoading) const LinearProgressIndicator(),
              RiskNoticeBanner(
                bannerKey: const Key('openresty-risk-banner'),
                notices:
                    localizeOpenRestyRiskNotices(context, provider.riskNotices),
                title: l10n.openrestyRiskBannerTitle,
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-status'),
                title: l10n.openrestyTabStatus,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: l10n.openrestyRunningStatusLabel,
                        value: openRestyStatusSummary(context, provider)),
                    OpenRestySummaryLine(
                        label: l10n.openrestyBuildVersionLabel,
                        value: openRestyBuildSummary(context, provider)),
                    OpenRestySummaryLine(
                        label: l10n.openrestyCoreSummaryLabel,
                        value: openRestyConfigSummary(context, provider)),
                    OpenRestySummaryLine(
                        label: l10n.openrestyHttpsSummaryLabel,
                        value: openRestyHttpsSummary(context, provider)),
                    OpenRestySummaryLine(
                        label: l10n.openrestyModulesSummaryLabel,
                        value: openRestyModulesSummary(context, provider)),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-https'),
                title: l10n.openrestyTabHttps,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: l10n.openrestyCurrentStateLabel,
                        value: openRestyHttpsSummary(context, provider)),
                    OpenRestySummaryLine(
                      label: l10n.openrestyRejectHandshakeLabel,
                      value: provider.https?['sslRejectHandshake'] == true
                          ? l10n.systemSettingsEnabled
                          : l10n.systemSettingsDisabled,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              OpenRestyCenterDialogs.showHttpsDialog(
                            context,
                            provider,
                          ),
                          icon: const Icon(Icons.lock_outline),
                          label: Text(l10n.openrestyEditHttpsAction),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.httpsDraft?.hasChanges == true
                              ? () {}
                              : null,
                          icon: const Icon(Icons.preview_outlined),
                          label: Text(l10n.openrestyPreviewDiffAction),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.httpsRollbackSnapshot == null
                              ? null
                              : provider.rollbackHttps,
                          icon: const Icon(Icons.history),
                          label: Text(l10n.openrestyRollbackAction),
                        ),
                      ],
                    ),
                    ConfigDiffPreviewCard(
                      title: l10n.openrestyHttpsDiffPreviewTitle,
                      items: localizeOpenRestyDiffItems(
                        context,
                        provider.httpsDraft?.diffItems ?? const [],
                      ),
                      onApply: provider.applyHttpsDraft,
                      onDiscard: provider.discardHttpsDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-modules'),
                title: l10n.openrestyTabModules,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final module in provider.moduleList.take(4))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(module.name ?? l10n.openrestyUnnamedModule),
                        subtitle: Text(module.packages ?? '-'),
                        trailing: Switch(
                          value: module.enable ?? false,
                          onChanged: (_) =>
                              OpenRestyCenterDialogs.showModuleDialog(
                            context,
                            provider,
                            module,
                          ),
                        ),
                        onTap: () => OpenRestyCenterDialogs.showModuleDialog(
                          context,
                          provider,
                          module,
                        ),
                      ),
                    if (provider.moduleList.isEmpty)
                      Text(l10n.openrestyNoModulesReturned),
                    ConfigDiffPreviewCard(
                      title: l10n.openrestyModuleDiffPreviewTitle,
                      items: localizeOpenRestyDiffItems(
                        context,
                        provider.moduleDraft?.diffItems ?? const [],
                      ),
                      onApply: provider.applyModuleDraft,
                      onDiscard: provider.discardModuleDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-config'),
                title: l10n.openrestyTabConfig,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: l10n.openrestyCurrentConfigLabel,
                        value: openRestyConfigSummary(context, provider)),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              OpenRestyCenterDialogs.showConfigDialog(
                            context,
                            provider,
                          ),
                          icon: const Icon(Icons.edit_note),
                          label: Text(l10n.openrestyPreviewDiffAction),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.configRollbackSnapshot == null
                              ? null
                              : provider.rollbackConfig,
                          icon: const Icon(Icons.history),
                          label: Text(l10n.openrestyRollbackAction),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openSourceEditor(context, provider),
                          icon: const Icon(Icons.code),
                          label: Text(l10n.openrestyAdvancedAction),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDesignTokens.spacingSm),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      child: Text(
                        provider.configContent.trim().isEmpty
                            ? '-'
                            : provider.configContent
                                .split('\n')
                                .take(6)
                                .join('\n'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                    ConfigDiffPreviewCard(
                      title: l10n.openrestyConfigDiffPreviewTitle,
                      items: localizeOpenRestyDiffItems(
                        context,
                        provider.configDraft?.diffItems ?? const [],
                      ),
                      onApply: provider.applyConfigDraft,
                      onDiscard: provider.discardConfigDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-build'),
                title: l10n.openrestyTabBuild,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: l10n.openrestyBuildMirrorLabel,
                        value: openRestyBuildSummary(context, provider)),
                    OpenRestySummaryLine(
                        label: l10n.openrestyBuildLastResultLabel,
                        value: provider.lastBuildMessage == null
                            ? l10n.openrestyBuildNoRecentAction
                            : l10n.openrestyBuildSubmittedMessage),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    FilledButton.icon(
                      onPressed: () => OpenRestyCenterDialogs.showBuildDialog(
                        context,
                        provider,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.openrestyBuildStartAction),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSourceEditor(
    BuildContext context,
    OpenRestyProvider provider,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<OpenRestyProvider>.value(
          value: provider,
          child: const OpenRestySourceEditorPage(),
        ),
      ),
    );
  }
}
