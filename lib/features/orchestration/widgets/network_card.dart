import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';
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
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(network.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _DetailLine(label: l10n.containerNetworkIdLabel, value: network.id),
                _DetailLine(
                    label: l10n.containerNetworkDriverLabel,
                    value: network.driver),
                _DetailLine(
                    label: l10n.containerNetworkScopeLabel,
                    value: network.scope),
                _DetailLine(
                  label: l10n.containerNetworkInternalLabel,
                  value: network.internal == null
                      ? null
                      : (network.internal!
                          ? l10n.commonYes
                          : l10n.commonNo),
                ),
                _DetailLine(
                  label: l10n.containerNetworkAttachableLabel,
                  value: network.attachable == null
                      ? null
                      : (network.attachable!
                          ? l10n.commonYes
                          : l10n.commonNo),
                ),
                _DetailLine(
                    label: l10n.containerNetworkSubnetLabel,
                    value: network.subnet),
                _DetailLine(
                    label: l10n.containerNetworkGatewayLabel,
                    value: network.gateway),
              ],
            ),
          ),
        );
      },
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.commonDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(16),
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
              icon: const Icon(Icons.info_outline),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
              child: Text((value == null || value!.isEmpty) ? '-' : value!)),
        ],
      ),
    );
  }
}
