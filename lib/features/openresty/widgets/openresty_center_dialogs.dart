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

  static Future<void> showModuleDialog(
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

  static Future<void> showConfigDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
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

  static Future<void> showBuildDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final mirrorController = TextEditingController(
      text: provider.modules?['mirror']?.toString() ?? '',
    );
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
                    content: Text(
                      provider.lastBuildMessage ??
                          context.l10n.commonSaveSuccess,
                    ),
                  ),
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
