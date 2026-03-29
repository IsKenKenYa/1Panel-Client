import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_routing_rules_provider.dart';

class WebsiteRoutingRulesSingleActions {
  static Future<void> showFileEditorDialog(
    BuildContext context, {
    required String title,
    required String initialName,
    required String initialContent,
    required Future<void> Function(String name, String content) onSubmit,
  }) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: initialName);
    final contentController = TextEditingController(text: initialContent);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
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
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await onSubmit(
                    nameController.text.trim(), contentController.text);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                showSnackBar(context, l10n.commonSaveSuccess);
              } catch (e) {
                showSnackBar(context, '${l10n.commonSaveFailed}: $e');
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    nameController.dispose();
    contentController.dispose();
  }

  static Future<void> showProxyStatusDialog(
    BuildContext context,
    WebsiteRoutingRulesProvider provider,
  ) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: provider.proxyName);
    var enabled = provider.proxyStatus != 'Disable';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Proxy Status / Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable'),
                value: enabled,
                onChanged: (value) => setStateDialog(() => enabled = value),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await provider.deleteProxy(name: nameController.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  showSnackBar(context, l10n.websitesOperateSuccess);
                } catch (e) {
                  showSnackBar(context, '${l10n.websitesOperateFailed}: $e');
                }
              },
              child: Text(l10n.commonDelete),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await provider.updateProxyStatus(
                    enabled: enabled,
                    name: nameController.text.trim(),
                  );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  showSnackBar(context, l10n.commonSaveSuccess);
                } catch (e) {
                  showSnackBar(context, '${l10n.commonSaveFailed}: $e');
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
