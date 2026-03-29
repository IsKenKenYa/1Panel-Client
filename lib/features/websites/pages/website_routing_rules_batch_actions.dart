import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_routing_rules_provider.dart';
import 'website_routing_rules_single_actions.dart';

enum RoutingBatchAction {
  proxyStatus,
  deleteProxy,
  redirectFile,
  loadBalancerFile,
}

class WebsiteRoutingRulesBatchActions {
  static Future<void> showBatchDialog(
    BuildContext context,
    WebsiteRoutingRulesProvider provider, {
    required int websiteId,
  }) async {
    final idsController = TextEditingController(text: '$websiteId');
    final nameController = TextEditingController(text: provider.proxyName);
    final contentController = TextEditingController();
    var action = RoutingBatchAction.proxyStatus;
    var enabled = provider.proxyStatus != 'Disable';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Batch Actions'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<RoutingBatchAction>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: const <DropdownMenuItem<RoutingBatchAction>>[
                    DropdownMenuItem(
                      value: RoutingBatchAction.proxyStatus,
                      child: Text('Batch Proxy Status'),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.deleteProxy,
                      child: Text('Batch Delete Proxy'),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.redirectFile,
                      child: Text('Batch Redirect File'),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.loadBalancerFile,
                      child: Text('Batch Load Balancer File'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setStateDialog(() {
                      action = value;
                      if (value == RoutingBatchAction.redirectFile) {
                        nameController.text = provider.redirectName;
                        contentController.text = provider.redirectContent;
                      } else if (value == RoutingBatchAction.loadBalancerFile) {
                        nameController.text = provider.loadBalancerName;
                        contentController.text = provider.loadBalancerContent;
                      } else {
                        nameController.text = provider.proxyName;
                      }
                    });
                  },
                ),
                TextField(
                  controller: idsController,
                  decoration: const InputDecoration(
                    labelText: 'Website IDs (comma separated)',
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (action == RoutingBatchAction.proxyStatus)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable'),
                    value: enabled,
                    onChanged: (value) => setStateDialog(() => enabled = value),
                  ),
                if (action == RoutingBatchAction.redirectFile ||
                    action == RoutingBatchAction.loadBalancerFile)
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
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final ids = parseWebsiteIds(idsController.text);
                if (ids.isEmpty) {
                  WebsiteRoutingRulesSingleActions.showSnackBar(
                    context,
                    'No valid website IDs.',
                  );
                  return;
                }

                final result = switch (action) {
                  RoutingBatchAction.proxyStatus =>
                    await provider.batchUpdateProxyStatus(
                      websiteIds: ids,
                      enabled: enabled,
                      name: nameController.text.trim(),
                    ),
                  RoutingBatchAction.deleteProxy =>
                    await provider.batchDeleteProxy(
                      websiteIds: ids,
                      name: nameController.text.trim(),
                    ),
                  RoutingBatchAction.redirectFile =>
                    await provider.batchSaveRedirectFile(
                      websiteIds: ids,
                      name: nameController.text.trim(),
                      content: contentController.text,
                    ),
                  RoutingBatchAction.loadBalancerFile =>
                    await provider.batchSaveLoadBalancerFile(
                      websiteIds: ids,
                      name: nameController.text.trim(),
                      content: contentController.text,
                    ),
                };

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                WebsiteRoutingRulesSingleActions.showSnackBar(
                  context,
                  'Batch done: success ${result.succeeded}, failed ${result.failed}.',
                );
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    idsController.dispose();
    nameController.dispose();
    contentController.dispose();
  }

  static List<int> parseWebsiteIds(String raw) {
    return raw
        .split(RegExp(r'[,\s]+'))
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
  }
}
