import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import '../../../core/utils/snackbar_utils.dart';

class OpenRestyCenterDialogs {
  const OpenRestyCenterDialogs._();

  static Future<void> showHttpsDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final l10n = context.l10n;
    bool enabled = provider.https?['https'] == true;
    bool rejectHandshake = provider.https?['sslRejectHandshake'] == true;
    await showAdaptiveFormPanel<void>(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AppFormPanel(
          title: l10n.openrestyDialogUpdateHttpsTitle,
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
          confirmLabel: l10n.openrestyPreviewDiffAction,
          onConfirm: () async {
            provider.stageHttpsUpdate(
              httpsEnabled: enabled,
              sslRejectHandshake: rejectHandshake,
            );
            Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }

  static Future<void> showModuleDialog(
    BuildContext context,
    OpenRestyProvider provider,
    OpenrestyModule module,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _OpenRestyModuleForm(provider: provider, module: module),
    );
  }

  static Future<void> showConfigDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    final l10n = context.l10n;
    final config = await showAppTextInputDialog(
      context,
      title: l10n.openrestyDialogPreviewConfigTitle,
      initialValue: provider.configContent,
      labelText: l10n.openrestyDialogConfigSourceLabel,
      maxLines: 16,
      trim: false,
      allowEmpty: true,
      autofocus: false,
      confirmLabel: l10n.openrestyPreviewDiffAction,
    );
    if (config != null && context.mounted) {
      provider.stageConfigUpdate(config);
    }
  }

  static Future<void> showBuildDialog(
    BuildContext context,
    OpenRestyProvider provider,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _OpenRestyBuildForm(provider: provider),
    );
  }
}

class _OpenRestyModuleForm extends StatefulWidget {
  const _OpenRestyModuleForm({required this.provider, required this.module});

  final OpenRestyProvider provider;
  final OpenrestyModule module;

  @override
  State<_OpenRestyModuleForm> createState() => _OpenRestyModuleFormState();
}

class _OpenRestyModuleFormState extends State<_OpenRestyModuleForm> {
  late bool enabled = widget.module.enable ?? false;
  late final packagesController = TextEditingController(
    text: widget.module.packages ?? '',
  );
  late final paramsController = TextEditingController(
    text: widget.module.params ?? '',
  );
  late final scriptController = TextEditingController(
    text: widget.module.script ?? '',
  );

  @override
  void dispose() {
    packagesController.dispose();
    paramsController.dispose();
    scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final module = widget.module;
    return AppFormPanel(
      title: module.name ?? l10n.openrestyDialogModuleTitleFallback,
      content: Column(
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
              labelText: l10n.openrestyDialogPackagesLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: paramsController,
            decoration: InputDecoration(
              labelText: l10n.openrestyDialogParamsLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: scriptController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.openrestyDialogScriptLabel,
            ),
          ),
        ],
      ),
      confirmLabel: l10n.openrestyPreviewDiffAction,
      onConfirm: () async {
        widget.provider.stageModuleUpdate(
          module: module,
          enable: enabled,
          packages: packagesController.text.trim(),
          params: paramsController.text.trim(),
          script: scriptController.text.trim(),
        );
        Navigator.pop(context);
      },
    );
  }
}

class _OpenRestyBuildForm extends StatefulWidget {
  const _OpenRestyBuildForm({required this.provider});

  final OpenRestyProvider provider;

  @override
  State<_OpenRestyBuildForm> createState() => _OpenRestyBuildFormState();
}

class _OpenRestyBuildFormState extends State<_OpenRestyBuildForm> {
  late final mirrorController = TextEditingController(
    text: widget.provider.modules?['mirror']?.toString() ?? '',
  );
  final taskIdController = TextEditingController();

  @override
  void dispose() {
    mirrorController.dispose();
    taskIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.openrestyDialogStartBuildTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.openrestyDialogBuildRiskHint),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          TextField(
            controller: mirrorController,
            decoration: InputDecoration(
              labelText: l10n.openrestyBuildMirrorLabel,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          TextField(
            controller: taskIdController,
            decoration: InputDecoration(
              labelText: l10n.openrestyBuildTaskIdLabel,
            ),
          ),
        ],
      ),
      confirmLabel: l10n.openrestyBuildAction,
      onConfirm: () async {
        final mirror = mirrorController.text.trim();
        await widget.provider.buildOpenResty(
          mirror: mirror,
          taskId: taskIdController.text.trim(),
        );
        if (context.mounted) {
          Navigator.pop(context);
          SnackBarUtils.showSuccess(
            context,
            mirror.isEmpty
                ? l10n.openrestyBuildSubmittedMessage
                : l10n.openrestyBuildSubmittedWithMirrorMessage(mirror),
          );
        }
      },
    );
  }
}
