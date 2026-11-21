import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/widgets/vm_storage_usage.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 存储池分区：容量、可用量、状态启停与 VM 数量。
class VmStorageTab extends StatelessWidget {
  const VmStorageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingSm,
          ),
          child: Row(
            children: <Widget>[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.commonRefresh,
                onPressed: provider.isMutating ? null : provider.loadStorages,
              ),
              FilledButton.tonalIcon(
                onPressed: () => showVmStorageForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.vmStorageCreateAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading:
                provider.storageState.isLoading && provider.storages.isEmpty,
            isEmpty:
                provider.storages.isEmpty && provider.storageState.error == null,
            errorMessage: provider.storageState.error,
            onRetry: provider.loadStorages,
            emptyTitle: l10n.vmStorageEmptyTitle,
            emptyDescription: l10n.vmStorageEmptyDescription,
            emptyIcon: Icons.storage_outlined,
            emptyActionLabel: l10n.vmStorageCreateAction,
            onEmptyAction: () => showVmStorageForm(context),
            child: RefreshIndicator(
              onRefresh: provider.loadStorages,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingSm,
                  AppDesignTokens.spacingLg,
                  AppDesignTokens.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  ExpressiveSection(
                    title: l10n.vmTabStorages,
                    isBusy: provider.storages.isEmpty == false &&
                        provider.isMutating,
                    children: <Widget>[
                      for (final storage in provider.storages)
                        _StorageCard(storage: storage, provider: provider),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.storage, required this.provider});

  final VMStorageItem storage;
  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final running =
        storage.status == 'running' || storage.status == 'Running';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingMd + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: storage.error == null
                      ? scheme.secondaryContainer
                      : scheme.errorContainer,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.storage_outlined,
                  size: 20,
                  color: storage.error == null
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    VmStorageUsage(storage: storage, detailed: true),
                    if (storage.error != null &&
                        storage.error!.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        storage.error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ],
                    if (storage.description.isNotEmpty) ...[
                      const SizedBox(height: AppDesignTokens.spacingXs),
                      Text(
                        storage.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: running,
                onChanged: provider.isMutating
                    ? null
                    : (value) => _toggleStatus(context, storage, value),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: provider.isMutating
                  ? null
                  : () => _deleteStorage(context, storage),
              icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
              label: Text(
                l10n.commonDelete,
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(
      BuildContext context, VMStorageItem storage, bool enable) async {
    final l10n = context.l10n;
    try {
      await provider.updateStorage(VMStorageUpdate(
        id: storage.id,
        status: enable ? 'running' : 'stopped',
      ));
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }

  Future<void> _deleteStorage(
      BuildContext context, VMStorageItem storage) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.commonDelete,
      message: '${storage.name}\n${storage.path}',
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await provider.deleteStorage(storage.id);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, error.toString());
    }
  }
}

/// 打开存储池创建弹层。
Future<void> showVmStorageForm(BuildContext context) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => const _VmStorageForm(),
  );
}

class _VmStorageForm extends StatefulWidget {
  const _VmStorageForm();

  @override
  State<_VmStorageForm> createState() => _VmStorageFormState();
}

class _VmStorageFormState extends State<_VmStorageForm> {
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _autoStart = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'pool-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.vmStorageCreateAction,
      isSaving: _saving,
      confirmLabel: l10n.commonCreate,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.vmStorageNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: InputDecoration(
              labelText: l10n.vmStoragePathLabel,
              hintText: '/var/lib/libvirt/images',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoStart,
            title: Text(l10n.vmStorageAutoStartLabel),
            onChanged: (value) => setState(() => _autoStart = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.commonDescription),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    final name = _nameController.text.trim();
    final path = _pathController.text.trim();
    if (name.isEmpty || path.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    setState(() => _saving = true);
    try {
      await provider.createStorage(VMStorageCreate(
        name: name,
        type: 'dir',
        path: path,
        autoStart: _autoStart,
        description: _descriptionController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}
