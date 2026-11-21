import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_actions.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_card.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_dialogs.dart';
import 'package:onepanel_client/features/vm/widgets/vm_monitor_dialog.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 虚拟机实例分区：列表、筛选与创建入口。
class VmInstanceTab extends StatelessWidget {
  const VmInstanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();

    return Column(
      children: <Widget>[
        _InstanceToolbar(provider: provider),
        Expanded(
          child: AsyncStatePageBodyWidget(
            isLoading: provider.vmState.isLoading && provider.vms.isEmpty,
            isEmpty: provider.vms.isEmpty && provider.vmState.error == null,
            errorMessage: provider.vmState.error,
            onRetry: provider.loadVms,
            emptyTitle: l10n.vmInstanceEmptyTitle,
            emptyDescription: l10n.vmInstanceEmptyDescription,
            emptyIcon: Icons.computer_outlined,
            emptyActionLabel:
                provider.canCreateVm && provider.environmentReady
                    ? l10n.vmInstanceCreateAction
                    : null,
            onEmptyAction: () => showVmCreateDialog(context),
            child: RefreshIndicator(
              onRefresh: provider.loadVms,
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
                    title: l10n.vmTabInstances,
                    isBusy: provider.vmState.isLoading,
                    children: <Widget>[
                      for (final vm in provider.vms)
                        VmInstanceCard(
                          vm: vm,
                          onOpenActions: () =>
                              showVmInstanceActions(context, vm),
                        ),
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

class _InstanceToolbar extends StatelessWidget {
  const _InstanceToolbar({required this.provider});

  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canCreate = provider.canCreateVm && provider.environmentReady;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ModuleSearchField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: provider.setVmSearch,
                  hintText: l10n.vmInstanceSearchHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              IconButton(
                icon: const Icon(Icons.sync_outlined),
                tooltip: l10n.vmInstanceSyncAction,
                onPressed: provider.isMutating ? null : provider.syncVms,
              ),
              const SizedBox(width: AppDesignTokens.spacingXs),
              FilledButton.tonalIcon(
                onPressed: canCreate
                    ? () => showVmCreateDialog(context)
                    : null,
                icon: const Icon(Icons.add),
                label: Text(l10n.vmInstanceCreateAction),
              ),
            ],
          ),
          if (provider.vmLimit > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    canCreate
                        ? Icons.info_outline
                        : Icons.warning_amber_outlined,
                    size: 16,
                    color: canCreate ? scheme.onSurfaceVariant : scheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      canCreate
                          ? '${l10n.vmInstanceQuotaLabel}: ${provider.vms.length}/${provider.vmLimit}'
                          : l10n.vmInstanceQuotaReached,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (!provider.environmentReady && provider.environmentState.error == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.vmInstanceCreateDisabledHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.tertiary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 打开创建虚拟机表单。
Future<void> showVmCreateDialog(BuildContext context) {
  return VmInstanceForm.show(context);
}

/// 打开实例操作菜单。
Future<void> showVmInstanceActions(BuildContext context, VMItem vm) async {
  final provider = context.read<VmProvider>();
  final l10n = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final options = <_VmActionOption>[
        if (VmStatus.canOpenConsole(vm))
          _VmActionOption('console', l10n.vmInstanceActionConsole,
              Icons.desktop_windows_outlined),
        if (VmStatus.isRunning(vm) || vm.status == 'blocked')
          _VmActionOption(
              'monitor', l10n.vmInstanceActionMonitor, Icons.monitor_heart_outlined),
        _VmActionOption('detail', l10n.vmInstanceActionDetail,
            Icons.info_outline),
        if (VmStatus.canInspectResources(vm))
          _VmActionOption('health', l10n.vmInstanceActionHealthCheck,
              Icons.medical_services_outlined),
        if (VmStatus.canOperate(vm, 'start'))
          _VmActionOption('start', l10n.vmInstanceActionStart, Icons.play_arrow),
        if (VmStatus.canOperate(vm, 'shutdown'))
          _VmActionOption(
              'shutdown', l10n.vmInstanceActionShutdown, Icons.power_settings_new),
        if (VmStatus.canOperate(vm, 'reboot'))
          _VmActionOption('reboot', l10n.vmInstanceActionReboot, Icons.restart_alt),
        if (VmStatus.canOperate(vm, 'suspend'))
          _VmActionOption('suspend', l10n.vmInstanceActionSuspend, Icons.pause),
        if (VmStatus.canOperate(vm, 'resume'))
          _VmActionOption('resume', l10n.vmInstanceActionResume, Icons.play_circle_outline),
        if (VmStatus.canOperate(vm, 'destroy'))
          _VmActionOption('destroy', l10n.vmInstanceActionDestroy, Icons.dangerous_outlined),
        if (VmStatus.canEdit(vm))
          _VmActionOption('edit', l10n.vmInstanceActionEdit, Icons.edit_outlined),
        _VmActionOption('rename', l10n.vmInstanceActionRename, Icons.drive_file_rename_outline),
        if (VmStatus.canResizeDisk(vm))
          _VmActionOption('resize', l10n.vmInstanceActionDisk, Icons.storage_outlined),
        if (VmStatus.canInspectResources(vm))
          _VmActionOption('snapshot', l10n.vmInstanceActionSnapshot,
              Icons.history_outlined),
        if (VmStatus.canEdit(vm))
          _VmActionOption('template', l10n.vmInstanceActionTemplate,
              Icons.copy_all_outlined),
        _VmActionOption('delete', l10n.vmInstanceActionDelete, Icons.delete_outline,
            destructive: true),
      ];
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final option in options)
              ListTile(
                leading: Icon(
                  option.icon,
                  color: option.destructive
                      ? Theme.of(sheetContext).colorScheme.error
                      : null,
                ),
                title: Text(
                  option.label,
                  style: option.destructive
                      ? TextStyle(
                          color: Theme.of(sheetContext).colorScheme.error)
                      : null,
                ),
                onTap: () => Navigator.of(sheetContext).pop(option.id),
              ),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case 'console':
      await showVmConsole(context, vm, provider);
    case 'monitor':
      await showVmMonitorDialog(context, vm);
    case 'detail':
      await showVmDetailDialog(context, vm, provider);
    case 'health':
      await showVmHealthCheckDialog(context, vm, provider);
    case 'start':
    case 'shutdown':
    case 'reboot':
    case 'suspend':
    case 'resume':
    case 'destroy':
      await _operateVm(context, provider, vm, action);
    case 'edit':
      await VmInstanceForm.show(context, editing: vm);
    case 'rename':
      await showVmRenameDialog(context, vm, provider);
    case 'resize':
      await showVmResizeDialog(context, vm, provider);
    case 'snapshot':
      await showVmSnapshotDialog(context, vm, provider);
    case 'template':
      await showVmConvertTemplateDialog(context, vm, provider);
    case 'delete':
      await showVmDeleteDialog(context, vm, provider);
  }
}

Future<void> _operateVm(
  BuildContext context,
  VmProvider provider,
  VMItem vm,
  String operation,
) async {
  final l10n = context.l10n;
  final label = _operationLabel(l10n, operation);
  final confirmed = await ConfirmActionSheetWidget.show(
    context,
    title: label,
    message: l10n.vmInstanceOperateConfirm(vm.name, label),
    confirmLabel: label,
    isDestructive: operation == 'destroy' || operation == 'shutdown',
  );
  if (!confirmed || !context.mounted) return;
  try {
    await provider.operate(vm.name, operation);
    if (!context.mounted) return;
    SnackBarUtils.showSuccess(context, l10n.vmInstanceOperateCompleted(label));
  } catch (error) {
    if (!context.mounted) return;
    SnackBarUtils.showError(context, error.toString());
  }
}

class _VmActionOption {
  const _VmActionOption(this.id, this.label, this.icon,
      {this.destructive = false});

  final String id;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// 电源操作的操作名文案。
String _operationLabel(l10n, String operation) {
  switch (operation) {
    case 'start':
      return l10n.vmInstanceActionStart;
    case 'shutdown':
      return l10n.vmInstanceActionShutdown;
    case 'reboot':
      return l10n.vmInstanceActionReboot;
    case 'suspend':
      return l10n.vmInstanceActionSuspend;
    case 'resume':
      return l10n.vmInstanceActionResume;
    case 'destroy':
      return l10n.vmInstanceActionDestroy;
    default:
      return operation;
  }
}
