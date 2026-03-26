import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';
import 'package:onepanel_client/features/group/widgets/group_edit_sheet_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_list_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class GroupSelectorSheetWidget extends StatelessWidget {
  const GroupSelectorSheetWidget({
    super.key,
    this.allowClearSelection = false,
    this.clearOptionLabel,
  });

  final bool allowClearSelection;
  final String? clearOptionLabel;

  static Future<int?> show(
    BuildContext context, {
    required String groupType,
    int? initialSelectedGroupId,
    bool allowClearSelection = false,
    String? clearOptionLabel,
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
            child: GroupSelectorSheetWidget(
              allowClearSelection: allowClearSelection,
              clearOptionLabel: clearOptionLabel,
            ),
          );
        }
        return ChangeNotifierProvider<GroupOptionsProvider>(
          create: (_) => GroupOptionsProvider()
            ..initialize(
              groupType: groupType,
              selectedGroupId: initialSelectedGroupId,
              allowEmptySelection: allowClearSelection,
            ),
          child: GroupSelectorSheetWidget(
            allowClearSelection: allowClearSelection,
            clearOptionLabel: clearOptionLabel,
          ),
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
                  child: GroupSelectorListWidget(
                    provider: provider,
                    allowClearSelection: allowClearSelection,
                    clearOptionLabel: clearOptionLabel,
                    onEditGroup: (group) => _openEditor(
                      context,
                      provider,
                      group: group,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
