import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

import '../providers/website_routing_rules_provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';

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
    final l10n = context.l10n;
    final idsController = TextEditingController(text: '$websiteId');
    final nameController = TextEditingController(text: provider.proxyName);
    final contentController = TextEditingController();
    var action = RoutingBatchAction.proxyStatus;
    var enabled = provider.proxyStatus != 'Disable';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(l10n.routingRulesBatchActions),
          content: SizedBox(width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<RoutingBatchAction>(
                  initialValue: action,
                  decoration: InputDecoration(labelText: l10n.commonAction),
                  items: <DropdownMenuItem<RoutingBatchAction>>[
                    DropdownMenuItem(
                      value: RoutingBatchAction.proxyStatus,
                      child: Text(l10n.routingRulesBatchProxyStatus),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.deleteProxy,
                      child: Text(l10n.routingRulesBatchDeleteProxy),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.redirectFile,
                      child: Text(l10n.routingRulesBatchRedirectFile),
                    ),
                    DropdownMenuItem(
                      value: RoutingBatchAction.loadBalancerFile,
                      child: Text(l10n.routingRulesBatchLoadBalancerFile),
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
                  decoration: InputDecoration(
                    labelText: l10n.commonWebsiteIds,
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.commonName),
                ),
                if (action == RoutingBatchAction.proxyStatus)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.commonEnable),
                    value: enabled,
                    onChanged: (value) => setStateDialog(() => enabled = value),
                  ),
                if (action == RoutingBatchAction.redirectFile ||
                    action == RoutingBatchAction.loadBalancerFile)
                  TextField(
                    controller: contentController,
                    minLines: 8,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: l10n.commonContent,
                      border: const OutlineInputBorder(),
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
                  SnackBarUtils.showError(
                      context, l10n.routingRulesBatchInvalidIds);
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
                final batchMsg = l10n.routingRulesBatchResult(
                    result.succeeded, result.failed);
                if (result.failed > 0) {
                  SnackBarUtils.showWarning(context, batchMsg);
                } else {
                  SnackBarUtils.showSuccess(context, batchMsg);
                }
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
