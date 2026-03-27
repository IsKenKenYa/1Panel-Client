import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/openresty/widgets/openresty_center_dialogs.dart';
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
        if (provider.error != null && !provider.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('OpenResty Gateway')),
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
            title: const Text('OpenResty Gateway'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.l10n.commonRefresh,
                onPressed: provider.refresh,
              ),
              IconButton(
                icon: const Icon(Icons.code),
                tooltip: 'Advanced source editor',
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
                notices: provider.riskNotices,
                title: 'Gateway risk banner',
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-status'),
                title: 'Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: 'Running Status', value: provider.statusSummary),
                    OpenRestySummaryLine(
                        label: 'Build / Version', value: provider.buildSummary),
                    OpenRestySummaryLine(
                        label: 'Core Summary', value: provider.configSummary),
                    OpenRestySummaryLine(
                        label: 'HTTPS Summary', value: provider.httpsSummary),
                    OpenRestySummaryLine(
                        label: 'Modules Summary',
                        value: provider.modulesSummary),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-https'),
                title: 'HTTPS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: 'Current State', value: provider.httpsSummary),
                    OpenRestySummaryLine(
                      label: 'Reject Handshake',
                      value: provider.https?['sslRejectHandshake'] == true
                          ? 'Enabled'
                          : 'Disabled',
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
                          label: const Text('Edit HTTPS'),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.httpsDraft?.hasChanges == true
                              ? () {}
                              : null,
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('Preview diff'),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.httpsRollbackSnapshot == null
                              ? null
                              : provider.rollbackHttps,
                          icon: const Icon(Icons.history),
                          label: const Text('Rollback'),
                        ),
                      ],
                    ),
                    ConfigDiffPreviewCard(
                      title: 'HTTPS diff preview',
                      items: provider.httpsDraft?.diffItems ?? const [],
                      onApply: provider.applyHttpsDraft,
                      onDiscard: provider.discardHttpsDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-modules'),
                title: 'Modules',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final module in provider.moduleList.take(4))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(module.name ?? 'Unnamed module'),
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
                      const Text('No modules returned by the gateway.'),
                    ConfigDiffPreviewCard(
                      title: 'Module diff preview',
                      items: provider.moduleDraft?.diffItems ?? const [],
                      onApply: provider.applyModuleDraft,
                      onDiscard: provider.discardModuleDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-config'),
                title: 'Config',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: 'Current Config', value: provider.configSummary),
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
                          label: const Text('Preview diff'),
                        ),
                        OutlinedButton.icon(
                          onPressed: provider.configRollbackSnapshot == null
                              ? null
                              : provider.rollbackConfig,
                          icon: const Icon(Icons.history),
                          label: const Text('Rollback'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openSourceEditor(context, provider),
                          icon: const Icon(Icons.code),
                          label: const Text('Advanced'),
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
                      title: 'Config diff preview',
                      items: provider.configDraft?.diffItems ?? const [],
                      onApply: provider.applyConfigDraft,
                      onDiscard: provider.discardConfigDraft,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              OpenRestySectionCard(
                sectionKey: const Key('openresty-section-build'),
                title: 'Build',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OpenRestySummaryLine(
                        label: 'Mirror', value: provider.buildSummary),
                    OpenRestySummaryLine(
                        label: 'Last Result',
                        value: provider.lastBuildMessage ??
                            'No recent build action'),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    FilledButton.icon(
                      onPressed: () => OpenRestyCenterDialogs.showBuildDialog(
                        context,
                        provider,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start build'),
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
