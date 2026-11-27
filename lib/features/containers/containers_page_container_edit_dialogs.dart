import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

class ContainersPageContainerEditDialogs {
  static Future<void> showRenameContainerDialog(
    BuildContext context,
    String name,
  ) async {
    final l10n = context.l10n;
    final result = await showAppTextInputDialog(
      context,
      title: l10n.containerActionRename,
      initialValue: name,
      labelText: l10n.commonName,
      trim: false,
      allowEmpty: true,
    );

    if (result != null &&
        result.isNotEmpty &&
        result != name &&
        context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.renameContainer(name, result);
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
        } else {
          SnackBarUtils.showError(
            context,
            l10n.containerOperateFailed(
              provider.data.error ?? l10n.commonUnknownError,
            ),
          );
        }
      }
    }
  }

  static Future<void> showEditContainerDialog(
    BuildContext context,
    ContainerInfo container,
  ) async {
    final l10n = context.l10n;
    await showAdaptiveFormPanel<void>(
      context,
      builder: (_) => _ContainerEditForm(
        container: container,
        onSubmit: (request) async {
          final provider = context.read<ContainersProvider>();
          final success = await provider.updateContainer(request);
          if (context.mounted) {
            if (success) {
              SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
            } else {
              SnackBarUtils.showError(
                context,
                l10n.containerOperateFailed(
                  provider.data.error ?? l10n.commonUnknownError,
                ),
              );
            }
          }
          return success;
        },
      ),
    );
  }

  static Future<void> showCleanLogDialog(
    BuildContext context,
    String name,
  ) async {
    final l10n = context.l10n;
    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.containerActionCleanLog,
      message: l10n.containerCleanLogConfirm(name),
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ContainersProvider>();
      final success = await provider.cleanContainerLog(name);
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
        } else {
          SnackBarUtils.showError(
            context,
            l10n.containerOperateFailed(
              provider.data.error ?? l10n.commonUnknownError,
            ),
          );
        }
      }
    }
  }
}

class _ContainerEditForm extends StatefulWidget {
  const _ContainerEditForm({required this.container, required this.onSubmit});

  final ContainerInfo container;
  final Future<bool> Function(ContainerOperate request) onSubmit;

  @override
  State<_ContainerEditForm> createState() => _ContainerEditFormState();
}

class _ContainerEditFormState extends State<_ContainerEditForm> {
  final _cpuController = TextEditingController();
  final _memoryController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cpuController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final request = ContainerOperate(
      name: widget.container.name,
      image: widget.container.image,
      cpuShares: int.tryParse(_cpuController.text),
      memory: int.tryParse(_memoryController.text),
    );
    setState(() => _saving = true);
    try {
      final success = await widget.onSubmit(request);
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.containerActionEdit,
      confirmLabel: l10n.commonConfirm,
      isSaving: _saving,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cpuController,
            decoration: InputDecoration(
              labelText: l10n.containerCpuShares,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoryController,
            decoration: InputDecoration(
              labelText: l10n.containerMemory,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      onConfirm: _submit,
    );
  }
}
