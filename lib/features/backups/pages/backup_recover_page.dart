import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/backups/widgets/backup_recover_confirm_step_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_recover_record_step_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_recover_resource_step_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/i18n/backup_l10n_helper.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class BackupRecoverPage extends StatefulWidget {
  const BackupRecoverPage({
    super.key,
    this.args,
  });

  final BackupRecoverArgs? args;

  @override
  State<BackupRecoverPage> createState() => _BackupRecoverPageState();
}

class _BackupRecoverPageState extends State<BackupRecoverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<BackupRecoverProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<BackupRecoverProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsBackupRecoverTitle,
          onServerChanged: () =>
              context.read<BackupRecoverProvider>().initialize(widget.args),
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: localizeBackupError(l10n, provider.errorMessage),
            onRetry: () => provider.initialize(widget.args),
            child: Stepper(
              currentStep: !provider.hasResourceSelection
                  ? 0
                  : provider.selectedRecord == null
                      ? 1
                      : 2,
              controlsBuilder: (_, __) => const SizedBox.shrink(),
              steps: <Step>[
                Step(
                  title: Text(l10n.backupRecoverResourceStepTitle),
                  content: BackupRecoverResourceStepWidget(provider: provider),
                ),
                Step(
                  title: Text(l10n.backupRecoverRecordStepTitle),
                  content: BackupRecoverRecordStepWidget(provider: provider),
                ),
                Step(
                  title: Text(l10n.backupRecoverConfirmStepTitle),
                  content: BackupRecoverConfirmStepWidget(
                    provider: provider,
                    onSubmit: _submit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.operationsBackupRecoverTitle,
      message: context.l10n.backupRecoverConfirmMessage,
      confirmLabel: context.l10n.commonConfirm,
      isDestructive: true,
      confirmIcon: Icons.restore_outlined,
    );
    if (!confirmed || !mounted) return;
    final success = await context.read<BackupRecoverProvider>().submitRecover();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizeBackupError(
                context.l10n,
                context.read<BackupRecoverProvider>().errorMessage,
              ) ??
              context.l10n.commonUnknownError,
        ),
      ),
    );
  }
}
