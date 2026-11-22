import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_sheet.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';
import 'orchestration_detail_line_widget.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key, required this.network});

  final DockerNetwork network;

  bool get _isSystemNetwork =>
      network.name == 'bridge' ||
      network.name == 'host' ||
      network.name == 'none';

  /// 驱动/子网/网关空值（模型层已归一 "null" 字面值）统一以 '—' 展示。
  String get _driverDisplay => network.driver.isEmpty ? '—' : network.driver;

  String _orDash(String? value) =>
      (value == null || value.isEmpty) ? '—' : value;

  Future<void> _runAction(
    BuildContext context,
    NetworkProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      return;
    }

    final error = provider.error ?? l10n.commonUnknownError;
    SnackBarUtils.showError(context, l10n.containerOperateFailed(error),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () => action(),
        ));
  }

  Future<void> _showDetailsSheet(BuildContext context) async {
    final l10n = context.l10n;
    String? yesNo(bool? value) =>
        value == null ? null : (value ? l10n.commonYes : l10n.commonNo);
    await showAppDetailsSheet(
      context,
      title: network.name,
      children: [
        OrchestrationDetailLineWidget(label: l10n.containerNetworkIdLabel, value: network.id),
        OrchestrationDetailLineWidget(label: l10n.containerNetworkDriverLabel, value: network.driver),
        OrchestrationDetailLineWidget(label: l10n.containerNetworkScopeLabel, value: network.scope),
        OrchestrationDetailLineWidget(
          label: l10n.containerNetworkInternalLabel,
          value: yesNo(network.internal),
        ),
        OrchestrationDetailLineWidget(
          label: l10n.containerNetworkAttachableLabel,
          value: yesNo(network.attachable),
        ),
        OrchestrationDetailLineWidget(label: l10n.containerNetworkSubnetLabel, value: network.subnet),
        OrchestrationDetailLineWidget(label: l10n.containerNetworkGatewayLabel, value: network.gateway),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NetworkProvider provider,
  ) async {
    final l10n = context.l10n;

    if (_isSystemNetwork) {
      SnackBarUtils.showSuccess(context, l10n.containerSystemProtectedNetwork);
      return;
    }

    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.commonDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirm != true || !context.mounted) return;
    await _runAction(
        context, provider, () => provider.removeNetwork(network.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<NetworkProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppDesignTokens.cardPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
                        label: Text(
                            l10n.containerNetworkDriverChip(_driverDisplay)),
                      ),
                      if (_isSystemNetwork)
                        Chip(
                          visualDensity: AdaptiveLayoutSpec.of(context).adaptiveDensity,
                          label: Text(l10n.containerNetworkSystemChip),
                        ),
                    ],
                  ),
                  Text(
                    '${l10n.containerNetworkSubnetLabel}: ${_orDash(network.subnet)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${l10n.containerNetworkGatewayLabel}: ${_orDash(network.gateway)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDetailsSheet(context),
              icon: const Icon(Icons.info_outlined),
              tooltip: l10n.commonMore,
            ),
            IconButton(
              tooltip: context.l10n.commonDelete,
              onPressed: provider.isLoading
                  ? null
                  : () => _confirmDelete(context, provider),
              icon: const Icon(Icons.delete_outline),
              color: _isSystemNetwork
                  ? theme.colorScheme.outline
                  : theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
