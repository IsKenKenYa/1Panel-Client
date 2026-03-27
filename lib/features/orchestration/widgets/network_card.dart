import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:provider/provider.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key, required this.network});

  final DockerNetwork network;

  bool get _isSystemNetwork =>
      network.name == 'bridge' ||
      network.name == 'host' ||
      network.name == 'none';

  Future<void> _runAction(
    BuildContext context,
    NetworkProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
      return;
    }

    final error = provider.error ?? l10n.commonUnknownError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.containerOperateFailed(error)),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () {
            action();
          },
        ),
      ),
    );
  }

  Future<void> _showDetailsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(network.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _DetailLine(label: 'ID', value: network.id),
              _DetailLine(label: 'Driver', value: network.driver),
              _DetailLine(label: 'Scope', value: network.scope),
              _DetailLine(
                label: 'Internal',
                value: network.internal == null
                    ? null
                    : (network.internal! ? 'true' : 'false'),
              ),
              _DetailLine(
                label: 'Attachable',
                value: network.attachable == null
                    ? null
                    : (network.attachable! ? 'true' : 'false'),
              ),
              _DetailLine(label: 'Subnet', value: network.subnet),
              _DetailLine(label: 'Gateway', value: network.gateway),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NetworkProvider provider,
  ) async {
    final l10n = context.l10n;

    if (_isSystemNetwork) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerSystemProtectedNetwork)),
      );
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
                        visualDensity: VisualDensity.compact,
                        label: Text('Driver: ${network.driver}'),
                      ),
                      if (_isSystemNetwork)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: const Text('System'),
                        ),
                    ],
                  ),
                  if (network.subnet != null)
                    Text(
                      '${l10n.containerNetworkSubnetLabel}: ${network.subnet}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (network.gateway != null)
                    Text(
                      '${l10n.containerNetworkGatewayLabel}: ${network.gateway}',
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
