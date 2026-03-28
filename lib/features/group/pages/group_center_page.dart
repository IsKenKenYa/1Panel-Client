import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/group_repository.dart';
import 'package:onepanel_client/features/group/providers/group_center_provider.dart';
import 'package:onepanel_client/features/group/widgets/group_edit_sheet_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:provider/provider.dart';

class GroupCenterPage extends StatefulWidget {
  const GroupCenterPage({
    super.key,
    this.provider,
  });

  final GroupCenterProvider? provider;

  @override
  State<GroupCenterPage> createState() => _GroupCenterPageState();
}

class _GroupCenterPageState extends State<GroupCenterPage> {
  late final GroupCenterProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? GroupCenterProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ChangeNotifierProvider<GroupCenterProvider>.value(
      value: _provider,
      child: Consumer<GroupCenterProvider>(
        builder: (context, provider, _) {
          return ServerAwarePageScaffold(
            title: l10n.operationsGroupCenterTitle,
            onServerChanged: () => provider.load(forceRefresh: true),
            actions: [
              IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
              ),
            ],
            floatingActionButton: FloatingActionButton.extended(
              onPressed: provider.isMutating
                  ? null
                  : () => _openEditor(context, provider),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonCreate),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.operationsGroupCenterDescription),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<GroupApiScope>(
                  segments: [
                    ButtonSegment<GroupApiScope>(
                      value: GroupApiScope.core,
                      label: Text(l10n.operationsGroupScopeCore),
                    ),
                    ButtonSegment<GroupApiScope>(
                      value: GroupApiScope.agent,
                      label: Text(l10n.operationsGroupScopeAgent),
                    ),
                  ],
                  selected: <GroupApiScope>{provider.scope},
                  onSelectionChanged: (Set<GroupApiScope> selection) {
                    provider.changeScope(selection.first);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      GroupCenterProvider.supportedTypes.map((String type) {
                    return ChoiceChip(
                      label: Text(_typeLabel(context, type)),
                      selected: provider.groupType == type,
                      onSelected: (_) => provider.changeGroupType(type),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading) const LinearProgressIndicator(),
                if (provider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                if (!provider.isLoading && provider.groups.isEmpty)
                  ModuleEmptyStateWidget(
                    title: l10n.operationsGroupSelectorTitle,
                    description: l10n.operationsGroupEmptyDescription,
                  )
                else
                  ...provider.groups.map((GroupInfo group) {
                    final groupName = (group.name ?? '').trim().isEmpty
                        ? l10n.operationsGroupDefaultLabel
                        : group.name!;
                    return Card(
                      child: ListTile(
                        title: Text(groupName),
                        subtitle: Text(
                          '${provider.scope.name} / ${_typeLabel(context, provider.groupType)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (group.isDefault == true)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(l10n.operationsGroupDefaultLabel),
                                ),
                              ),
                            IconButton(
                              onPressed: provider.isMutating || group.id == null
                                  ? null
                                  : () => _openEditor(
                                        context,
                                        provider,
                                        existing: group,
                                      ),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l10n.commonEdit,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _typeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (type) {
      'host' => l10n.operationsHostAssetsTitle,
      'command' => l10n.operationsCommandsTitle,
      'cronjob' => l10n.operationsCronjobsTitle,
      'backup' => l10n.operationsBackupsTitle,
      'website' => l10n.websitesPageTitle,
      'ssh' => l10n.operationsSshTitle,
      _ => type,
    };
  }

  Future<void> _openEditor(
    BuildContext context,
    GroupCenterProvider provider, {
    GroupInfo? existing,
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GroupEditSheetWidget(
        title: existing == null
            ? context.l10n.operationsGroupCreateTitle
            : context.l10n.operationsGroupRenameTitle,
        initialName: existing?.name,
        canDelete: existing?.id != null && existing?.isDefault != true,
        onSave: (String name) async {
          final success = existing?.id == null
              ? await provider.createGroup(name)
              : await provider.updateGroup(
                  id: existing!.id!,
                  name: name,
                  isDefault: existing.isDefault ?? false,
                );
          if (!success) {
            throw Exception(provider.error ?? 'group save failed');
          }
        },
        onDelete: existing?.id == null || existing?.isDefault == true
            ? null
            : () async {
                final success = await provider.deleteGroup(existing!.id!);
                if (!success) {
                  throw Exception(provider.error ?? 'group delete failed');
                }
              },
      ),
    );
  }
}
