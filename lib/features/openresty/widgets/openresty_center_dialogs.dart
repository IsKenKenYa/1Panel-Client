import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';

class OpenRestyCenterDialogs {
  const OpenRestyCenterDialogs._();

  static Future<void> showHttpsDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final l10n = context.l10n;
    bool enabled = provider.https?['https'] == true;
    bool rejectHandshake = provider.https?['sslRejectHandshake'] == true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.openrestyDialogUpdateHttpsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.openrestyDialogEnableHttpsLabel),
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.openrestyDialogRejectInvalidHandshakesLabel),
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
              child: Text(l10n.openrestyPreviewDiffAction),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showModuleDialog(
    BuildContext context,
    OpenRestyProvider provider,
    OpenrestyModule module,
  ) async {
    final l10n = context.l10n;
    bool enabled = module.enable ?? false;
    final packagesController =
        TextEditingController(text: module.packages ?? '');
    final paramsController = TextEditingController(text: module.params ?? '');
    final scriptController = TextEditingController(text: module.script ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(module.name ?? l10n.openrestyDialogModuleTitleFallback),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.openrestyDialogEnableModuleLabel),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                ),
                TextField(
                  controller: packagesController,
                  decoration: InputDecoration(
                      labelText: l10n.openrestyDialogPackagesLabel),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                TextField(
                  controller: paramsController,
                  decoration: InputDecoration(
                      labelText: l10n.openrestyDialogParamsLabel),
                ),
                const SizedBox(height: AppDesignTokens.spacingSm),
                TextField(
                  controller: scriptController,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: l10n.openrestyDialogScriptLabel),
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
              child: Text(l10n.openrestyPreviewDiffAction),
            ),
          ],
        ),
      ),
    );

    packagesController.dispose();
    paramsController.dispose();
    scriptController.dispose();
  }

  static Future<void> showConfigDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: provider.configContent);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.openrestyDialogPreviewConfigTitle),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            maxLines: 16,
            decoration: InputDecoration(
              labelText: l10n.openrestyDialogConfigSourceLabel,
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
            child: Text(l10n.openrestyPreviewDiffAction),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  static Future<void> showBuildDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final l10n = context.l10n;
    final mirrorController = TextEditingController(
      text: provider.modules?['mirror']?.toString() ?? '',
    );
    final taskIdController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.openrestyDialogStartBuildTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.openrestyDialogBuildRiskHint,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            TextField(
              controller: mirrorController,
              decoration:
                  InputDecoration(labelText: l10n.openrestyBuildMirrorLabel),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            TextField(
              controller: taskIdController,
              decoration:
                  InputDecoration(labelText: l10n.openrestyBuildTaskIdLabel),
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
              final mirror = mirrorController.text.trim();
              await provider.buildOpenResty(
                mirror: mirror,
                taskId: taskIdController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      mirror.isEmpty
                          ? l10n.openrestyBuildSubmittedMessage
                          : l10n
                              .openrestyBuildSubmittedWithMirrorMessage(mirror),
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.openrestyBuildAction),
          ),
        ],
      ),
    );
    mirrorController.dispose();
    taskIdController.dispose();
  }
}
