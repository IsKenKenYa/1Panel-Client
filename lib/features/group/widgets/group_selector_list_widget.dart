import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';

class GroupSelectorListWidget extends StatelessWidget {
  const GroupSelectorListWidget({
    super.key,
    required this.provider,
    required this.onEditGroup,
    this.allowClearSelection = false,
    this.clearOptionLabel,
  });

  final GroupOptionsProvider provider;
  final bool allowClearSelection;
  final String? clearOptionLabel;
  final Future<void> Function(GroupInfo group) onEditGroup;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: provider.isMutating,
      child: RadioGroup<int?>(
        groupValue: provider.selectedGroupId,
        onChanged: (int? value) => Navigator.of(context).pop(value),
        child: ListView.separated(
          itemCount: provider.groups.length + (allowClearSelection ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (allowClearSelection && index == 0) {
              return _GroupSelectorAllTile(
                label: clearOptionLabel ?? '',
                enabled: !provider.isMutating,
              );
            }

            final itemIndex = allowClearSelection ? index - 1 : index;
            final group = provider.groups[itemIndex];
            return _GroupSelectorGroupTile(
              group: group,
              enabled: !provider.isMutating,
              onEdit: group.isDefault == true ? null : () => onEditGroup(group),
            );
          },
        ),
      ),
    );
  }
}

class _GroupSelectorAllTile extends StatelessWidget {
  const _GroupSelectorAllTile({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<int?>(
        value: null,
      ),
      title: Text(label),
      onTap: enabled ? () => Navigator.of(context).pop(null) : null,
    );
  }
}

class _GroupSelectorGroupTile extends StatelessWidget {
  const _GroupSelectorGroupTile({
    required this.group,
    required this.enabled,
    this.onEdit,
  });

  final GroupInfo group;
  final bool enabled;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<int?>(
        value: group.id,
      ),
      title: Text(_displayName(context)),
      subtitle: group.isDefault == true
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(l10n.operationsGroupDefaultLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
          : null,
      trailing: onEdit == null
          ? null
          : IconButton(
              onPressed: enabled ? onEdit : null,
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
            ),
      onTap: enabled ? () => Navigator.of(context).pop(group.id) : null,
    );
  }

  String _displayName(BuildContext context) {
    final name = group.name?.trim();
    if (name == null || name.isEmpty) {
      return context.l10n.operationsGroupDefaultLabel;
    }
    return name;
  }
}
