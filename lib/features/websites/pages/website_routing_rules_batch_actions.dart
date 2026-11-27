import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

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
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _RoutingBatchForm(
        pageContext: context,
        provider: provider,
        websiteId: websiteId,
      ),
    );
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

class _RoutingBatchForm extends StatefulWidget {
  const _RoutingBatchForm({
    required this.pageContext,
    required this.provider,
    required this.websiteId,
  });

  final BuildContext pageContext;
  final WebsiteRoutingRulesProvider provider;
  final int websiteId;

  @override
  State<_RoutingBatchForm> createState() => _RoutingBatchFormState();
}

class _RoutingBatchFormState extends State<_RoutingBatchForm> {
  late final idsController = TextEditingController(text: '${widget.websiteId}');
  late final nameController = TextEditingController(
    text: widget.provider.proxyName,
  );
  final contentController = TextEditingController();
  var action = RoutingBatchAction.proxyStatus;
  late var enabled = widget.provider.proxyStatus != 'Disable';

  @override
  void dispose() {
    idsController.dispose();
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = widget.provider;
    final pageContext = widget.pageContext;

    return AppFormPanel(
      title: l10n.routingRulesBatchActions,
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(pageContext).dialogConstraints.maxWidth,
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
                setState(() {
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
              decoration: InputDecoration(labelText: l10n.commonWebsiteIds),
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
                onChanged: (value) => setState(() => enabled = value),
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
      confirmLabel: l10n.commonSave,
      onConfirm: () async {
        final ids = WebsiteRoutingRulesBatchActions.parseWebsiteIds(
          idsController.text,
        );
        if (ids.isEmpty) {
          SnackBarUtils.showError(
            pageContext,
            l10n.routingRulesBatchInvalidIds,
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
          RoutingBatchAction.deleteProxy => await provider.batchDeleteProxy(
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

        if (!context.mounted) return;
        Navigator.of(context).pop();
        if (!pageContext.mounted) return;
        final batchMsg = l10n.routingRulesBatchResult(
          result.succeeded,
          result.failed,
        );
        if (result.failed > 0) {
          SnackBarUtils.showWarning(pageContext, batchMsg);
        } else {
          SnackBarUtils.showSuccess(pageContext, batchMsg);
        }
      },
    );
  }
}
