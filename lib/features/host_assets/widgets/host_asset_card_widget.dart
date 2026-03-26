import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_test_state.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

class HostAssetCardWidget extends StatelessWidget {
  const HostAssetCardWidget({
    super.key,
    required this.host,
    required this.groupLabel,
    required this.testState,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onTest,
    required this.onDelete,
    required this.onMoveGroup,
  });

  final HostInfo host;
  final String groupLabel;
  final HostAssetTestState testState;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onDelete;
  final VoidCallback onMoveGroup;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AppCard(
      title: host.name,
      subtitle: Text(host.addr ?? ''),
      trailing: selectionMode
          ? Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoChip(label: host.user ?? '-'),
              _InfoChip(label: ':${host.port ?? 22}'),
              _InfoChip(label: host.authMode ?? 'password'),
              _InfoChip(label: groupLabel),
              _InfoChip(label: _statusLabel(l10n)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.commonEdit),
              ),
              OutlinedButton.icon(
                onPressed: onTest,
                icon: const Icon(Icons.power_outlined, size: 18),
                label: Text(l10n.hostAssetsTestAction),
              ),
              OutlinedButton.icon(
                onPressed: onMoveGroup,
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: Text(l10n.hostAssetsMoveGroupAction),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(dynamic l10n) {
    switch (testState.status) {
      case HostAssetTestStatus.success:
        return l10n.hostAssetsStatusSuccess;
      case HostAssetTestStatus.failure:
        return l10n.hostAssetsStatusFailed;
      case HostAssetTestStatus.notTested:
        return l10n.hostAssetsStatusNotTested;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
