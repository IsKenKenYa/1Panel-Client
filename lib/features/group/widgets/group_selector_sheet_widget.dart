import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';
import 'package:onepanel_client/features/group/widgets/group_edit_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class GroupSelectorSheetWidget extends StatelessWidget {
  const GroupSelectorSheetWidget({super.key});

  static Future<int?> show(
    BuildContext context, {
    required String groupType,
    int? initialSelectedGroupId,
    GroupOptionsProvider? provider,
  }) {
    return showModalBottomSheet<int?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        if (provider != null) {
          return ChangeNotifierProvider<GroupOptionsProvider>.value(
            value: provider,
            child: const GroupSelectorSheetWidget(),
          );
        }
        return ChangeNotifierProvider<GroupOptionsProvider>(
          create: (_) => GroupOptionsProvider()
            ..initialize(
              groupType: groupType,
              selectedGroupId: initialSelectedGroupId,
            ),
          child: const GroupSelectorSheetWidget(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<GroupOptionsProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.operationsGroupSelectorTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: provider.isMutating
                        ? null
                        : () => _openEditor(context, provider),
                    icon: const Icon(Icons.add),
                    tooltip: l10n.commonAdd,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 360,
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: () => provider.load(forceRefresh: true),
                  emptyTitle: l10n.commonEmpty,
                  emptyDescription: l10n.operationsGroupEmptyDescription,
                  emptyActionLabel: l10n.commonCreate,
                  onEmptyAction: () => _openEditor(context, provider),
                  child: ListView.separated(
                    itemCount: provider.groups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final group = provider.groups[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Radio<int?>(
                          value: group.id,
                        ),
                        title: Text(_displayName(context, group)),
                        subtitle: group.isDefault == true
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    label: Text(
                                      l10n.operationsGroupDefaultLabel,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              )
                            : null,
                        trailing: group.isDefault == true
                            ? null
                            : IconButton(
                                onPressed: provider.isMutating
                                    ? null
                                    : () => _openEditor(
                                          context,
                                          provider,
                                          group: group,
                                        ),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                              ),
                        onTap: provider.isMutating
                            ? null
                            : () {
                                provider.selectGroup(group.id);
                                Navigator.of(context).pop(group.id);
                              },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayName(BuildContext context, GroupInfo group) {
    final name = group.name?.trim();
    if (name == null || name.isEmpty) {
      return context.l10n.operationsGroupDefaultLabel;
    }
    return name;
  }

  Future<void> _openEditor(
    BuildContext context,
    GroupOptionsProvider provider, {
    GroupInfo? group,
  }) async {
    final l10n = context.l10n;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GroupEditSheetWidget(
        title: group == null
            ? l10n.operationsGroupCreateTitle
            : l10n.operationsGroupRenameTitle,
        initialName: group?.name,
        canDelete: group != null,
        onSave: (name) async {
          if (group == null) {
            await provider.createGroup(name);
          } else {
            await provider.updateGroup(
              id: group.id ?? 0,
              name: name,
              isDefault: group.isDefault ?? false,
            );
          }
          final errorMessage = provider.errorMessage;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            throw Exception(errorMessage);
          }
        },
        onDelete: group == null || group.id == null
            ? null
            : () async {
                await provider.deleteGroup(group.id!);
                final errorMessage = provider.errorMessage;
                if (errorMessage != null && errorMessage.isNotEmpty) {
                  throw Exception(errorMessage);
                }
              },
      ),
    );

    if (changed == true && context.mounted) {
      await provider.load(forceRefresh: true);
    }
  }
}
