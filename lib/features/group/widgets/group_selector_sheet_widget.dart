import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';
import 'package:onepanel_client/features/group/widgets/group_edit_sheet_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_list_widget.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class GroupSelectorSheetWidget extends StatelessWidget {
  const GroupSelectorSheetWidget({
    super.key,
    this.allowClearSelection = false,
    this.clearOptionLabel,
    this.showTitle = true,
  });

  final bool allowClearSelection;
  final String? clearOptionLabel;
  final bool showTitle;

  static Future<int?> show(
    BuildContext context, {
    required String groupType,
    int? initialSelectedGroupId,
    bool allowClearSelection = false,
    String? clearOptionLabel,
    GroupOptionsProvider? provider,
  }) {
    return showAppFormSheet<int>(
      context,
      title: context.l10n.operationsGroupSelectorTitle,
      builder: (_) {
        if (provider != null) {
          return ChangeNotifierProvider<GroupOptionsProvider>.value(
            value: provider,
            child: GroupSelectorSheetWidget(
              allowClearSelection: allowClearSelection,
              clearOptionLabel: clearOptionLabel,
              showTitle: false,
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
            showTitle: false,
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: showTitle
                        ? Text(
                            l10n.operationsGroupSelectorTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          )
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(kMinInteractiveDimension),
                      visualDensity: VisualDensity.standard,
                    ),
                    onPressed: provider.isMutating
                        ? null
                        : () => _openEditor(context, provider),
                    icon: const Icon(Icons.add_outlined),
                    tooltip: l10n.commonAdd,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
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
                      onEditGroup: (group) =>
                          _openEditor(context, provider, group: group),
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
    final changed = await showAppFormSheet<bool>(
      context,
      title: group == null
          ? l10n.operationsGroupCreateTitle
          : l10n.operationsGroupRenameTitle,
      builder: (_) => GroupEditSheetWidget(
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
