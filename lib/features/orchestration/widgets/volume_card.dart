import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_sheet.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_utils.dart';
import 'orchestration_detail_line_widget.dart';

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

    await showAppDetailsSheet(
      context,
      title: volume.name,
      children: [
        OrchestrationDetailLineWidget(
          label: l10n.volumeDetailDriver,
          value: volume.driver,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.volumeDetailMountpoint,
          value: volume.mountpoint,
        ),
        if (labels.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.volumeDetailLabels,
            value: labels.entries.map((entry) => '${entry.key}=${entry.value}').join(', '),
          ),
        if (options.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.volumeDetailOptions,
            value: options.entries.map((entry) => '${entry.key}=${entry.value}').join(', '),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VolumeProvider provider,
  ) async {
    final l10n = context.l10n;
    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: l10n.commonDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
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
        padding: AppDesignTokens.cardPadding,
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
              icon: const Icon(Icons.info_outlined),
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
