import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';
class VolumeCard extends StatelessWidget {
  const VolumeCard({super.key, required this.volume});

  final DockerVolume volume;

  Future<void> _runAction(
    BuildContext context,
    VolumeProvider provider,
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
    final labels = volume.labels ?? const <String, String>{};
    final options = volume.options ?? const <String, String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(volume.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _DetailLine(label: l10n.volumeDetailDriver, value: volume.driver),
              _DetailLine(label: l10n.volumeDetailMountpoint, value: volume.mountpoint),
              if (labels.isNotEmpty)
                _DetailLine(
                  label: l10n.volumeDetailLabels,
                  value: labels.entries
                      .map((entry) => '${entry.key}=${entry.value}')
                      .join(', '),
                ),
              if (options.isNotEmpty)
                _DetailLine(
                  label: l10n.volumeDetailOptions,
                  value: options.entries
                      .map((entry) => '${entry.key}=${entry.value}')
                      .join(', '),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VolumeProvider provider,
  ) async {
    final l10n = context.l10n;
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
        context, provider, () => provider.removeVolume(volume.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<VolumeProvider>();

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
                    volume.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.volumeDetailDriver}: ${volume.driver}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (volume.mountpoint != null)
                    Text(
                      '${l10n.volumeDetailMountpoint}: ${volume.mountpoint}',
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
              color: theme.colorScheme.error,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 95, child: Text(label)),
          Expanded(
              child: Text((value == null || value!.isEmpty) ? '-' : value!)),
        ],
      ),
    );
  }
}
