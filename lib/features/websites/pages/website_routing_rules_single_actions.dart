import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import '../providers/website_routing_rules_provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';

class WebsiteRoutingRulesSingleActions {
  static Future<void> showFileEditorDialog(
    BuildContext context, {
    required String title,
    required String initialName,
    required String initialContent,
    required Future<void> Function(String name, String content) onSubmit,
  }) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _RoutingFileForm(
        pageContext: context,
        title: title,
        initialName: initialName,
        initialContent: initialContent,
        onSubmit: onSubmit,
      ),
    );
  }

  static Future<void> showProxyStatusDialog(
    BuildContext context,
    WebsiteRoutingRulesProvider provider,
  ) async {
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) =>
          _ProxyStatusForm(pageContext: context, provider: provider),
    );
  }
}

class _RoutingFileForm extends StatefulWidget {
  const _RoutingFileForm({
    required this.pageContext,
    required this.title,
    required this.initialName,
    required this.initialContent,
    required this.onSubmit,
  });

  final BuildContext pageContext;
  final String title;
  final String initialName;
  final String initialContent;
  final Future<void> Function(String name, String content) onSubmit;

  @override
  State<_RoutingFileForm> createState() => _RoutingFileFormState();
}

class _RoutingFileFormState extends State<_RoutingFileForm> {
  late final nameController = TextEditingController(text: widget.initialName);
  late final contentController = TextEditingController(
    text: widget.initialContent,
  );

  @override
  void dispose() {
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pageContext = widget.pageContext;
    return AppFormPanel(
      title: widget.title,
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(pageContext).dialogConstraints.maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.commonName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () async {
        try {
          await widget.onSubmit(
            nameController.text.trim(),
            contentController.text,
          );
          if (!context.mounted) return;
          Navigator.of(context).pop();
          if (pageContext.mounted) {
            SnackBarUtils.showSuccess(pageContext, l10n.commonSaveSuccess);
          }
        } catch (e) {
          if (pageContext.mounted) {
            SnackBarUtils.showError(
              pageContext,
              '${l10n.commonSaveFailed}: $e',
            );
          }
        }
      },
    );
  }
}

class _ProxyStatusForm extends StatefulWidget {
  const _ProxyStatusForm({required this.pageContext, required this.provider});

  final BuildContext pageContext;
  final WebsiteRoutingRulesProvider provider;

  @override
  State<_ProxyStatusForm> createState() => _ProxyStatusFormState();
}

class _ProxyStatusFormState extends State<_ProxyStatusForm> {
  late final nameController = TextEditingController(
    text: widget.provider.proxyName,
  );
  late var enabled = widget.provider.proxyStatus != 'Disable';

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = widget.provider;
    final pageContext = widget.pageContext;
    return AppFormPanel(
      title: l10n.websiteRoutingProxyStatusDelete,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.commonName),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.commonStart),
            value: enabled,
            onChanged: (value) => setState(() => enabled = value),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () async {
                try {
                  await provider.deleteProxy(name: nameController.text.trim());
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  if (pageContext.mounted) {
                    SnackBarUtils.showSuccess(
                      pageContext,
                      l10n.websitesOperateSuccess,
                    );
                  }
                } catch (e) {
                  if (pageContext.mounted) {
                    SnackBarUtils.showError(
                      pageContext,
                      '${l10n.websitesOperateFailed}: $e',
                    );
                  }
                }
              },
              child: Text(l10n.commonDelete),
            ),
          ),
        ],
      ),
      confirmLabel: l10n.commonSave,
      onConfirm: () async {
        try {
          await provider.updateProxyStatus(
            enabled: enabled,
            name: nameController.text.trim(),
          );
          if (!context.mounted) return;
          Navigator.of(context).pop();
          if (pageContext.mounted) {
            SnackBarUtils.showSuccess(pageContext, l10n.commonSaveSuccess);
          }
        } catch (e) {
          if (pageContext.mounted) {
            SnackBarUtils.showError(
              pageContext,
              '${l10n.commonSaveFailed}: $e',
            );
          }
        }
      },
    );
  }
}
