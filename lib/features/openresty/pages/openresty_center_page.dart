import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
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
              _SectionCard(
                sectionKey: const Key('openresty-section-status'),
                title: 'Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryLine(
                        label: 'Running Status', value: provider.statusSummary),
                    _SummaryLine(
                        label: 'Build / Version', value: provider.buildSummary),
                    _SummaryLine(
                        label: 'Core Summary', value: provider.configSummary),
                    _SummaryLine(
                        label: 'HTTPS Summary', value: provider.httpsSummary),
                    _SummaryLine(
                        label: 'Modules Summary',
                        value: provider.modulesSummary),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              _SectionCard(
                sectionKey: const Key('openresty-section-https'),
                title: 'HTTPS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryLine(
                        label: 'Current State', value: provider.httpsSummary),
                    _SummaryLine(
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
                          onPressed: () => _showHttpsDialog(context, provider),
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
              _SectionCard(
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
                              _showModuleDialog(context, provider, module),
                        ),
                        onTap: () =>
                            _showModuleDialog(context, provider, module),
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
              _SectionCard(
                sectionKey: const Key('openresty-section-config'),
                title: 'Config',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryLine(
                        label: 'Current Config', value: provider.configSummary),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Wrap(
                      spacing: AppDesignTokens.spacingSm,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _showConfigDialog(context, provider),
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
              _SectionCard(
                sectionKey: const Key('openresty-section-build'),
                title: 'Build',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryLine(label: 'Mirror', value: provider.buildSummary),
                    _SummaryLine(
                        label: 'Last Result',
                        value: provider.lastBuildMessage ??
                            'No recent build action'),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    FilledButton.icon(
                      onPressed: () => _showBuildDialog(context, provider),
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
      BuildContext context, OpenRestyProvider provider) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<OpenRestyProvider>.value(
          value: provider,
          child: const OpenRestySourceEditorPage(),
        ),
      ),
    );
  }

  Future<void> _showHttpsDialog(
      BuildContext context, OpenRestyProvider provider) async {
    bool enabled = provider.https?['https'] == true;
    bool rejectHandshake = provider.https?['sslRejectHandshake'] == true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update HTTPS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable HTTPS'),
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reject invalid handshakes'),
                value: rejectHandshake,
                onChanged: (value) => setState(() => rejectHandshake = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                provider.stageHttpsUpdate(
                  httpsEnabled: enabled,
                  sslRejectHandshake: rejectHandshake,
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showModuleDialog(
    BuildContext context,
    OpenRestyProvider provider,
    OpenrestyModule module,
  ) async {
    bool enabled = module.enable ?? false;
    final packagesController =
        TextEditingController(text: module.packages ?? '');
    final paramsController = TextEditingController(text: module.params ?? '');
    final scriptController = TextEditingController(text: module.script ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(module.name ?? 'Module'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable module'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                ),
                TextField(
                  controller: packagesController,
                  decoration: const InputDecoration(labelText: 'Packages'),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                TextField(
                  controller: paramsController,
                  decoration: const InputDecoration(labelText: 'Params'),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                TextField(
                  controller: scriptController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Script'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                provider.stageModuleUpdate(
                  module: module,
                  enable: enabled,
                  packages: packagesController.text.trim(),
                  params: paramsController.text.trim(),
                  script: scriptController.text.trim(),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Preview'),
            ),
          ],
        ),
      ),
    );

    packagesController.dispose();
    paramsController.dispose();
    scriptController.dispose();
  }

  Future<void> _showConfigDialog(
      BuildContext context, OpenRestyProvider provider) async {
    final controller = TextEditingController(text: provider.configContent);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preview config change'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Config source',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              provider.stageConfigUpdate(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showBuildDialog(
      BuildContext context, OpenRestyProvider provider) async {
    final mirrorController = TextEditingController(
        text: provider.modules?['mirror']?.toString() ?? '');
    final taskIdController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start OpenResty build'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Build can refresh gateway binaries and module packages. Confirm before running on production nodes.',
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            TextField(
              controller: mirrorController,
              decoration: const InputDecoration(labelText: 'Mirror'),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            TextField(
              controller: taskIdController,
              decoration: const InputDecoration(labelText: 'Task ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              await provider.buildOpenResty(
                mirror: mirrorController.text.trim(),
                taskId: taskIdController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(provider.lastBuildMessage ??
                          context.l10n.commonSaveSuccess)),
                );
              }
            },
            child: const Text('Build'),
          ),
        ],
      ),
    );
    mirrorController.dispose();
    taskIdController.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.sectionKey,
    required this.title,
    required this.child,
  });

  final Key sectionKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
