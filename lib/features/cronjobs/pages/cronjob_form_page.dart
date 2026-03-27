import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_form_provider.dart';
import 'package:onepanel_client/features/cronjobs/utils/cronjob_form_l10n_helper.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_backup_target_section_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_basic_section_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_policy_section_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_schedule_section_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_shell_target_section_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_form_url_target_section_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class CronjobFormPage extends StatefulWidget {
  const CronjobFormPage({
    super.key,
    this.args,
  });

  final CronjobFormArgs? args;

  @override
  State<CronjobFormPage> createState() => _CronjobFormPageState();
}

class _CronjobFormPageState extends State<CronjobFormPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<CronjobFormProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CronjobFormProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: provider.isEditing
              ? l10n.cronjobFormEditTitle
              : l10n.cronjobFormCreateTitle,
          onServerChanged: () =>
              context.read<CronjobFormProvider>().initialize(widget.args),
          actions: <Widget>[
            if (provider.isEditing)
              IconButton(
                onPressed: provider.isDeleting ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.commonDelete,
              ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: localizeCronjobFormError(l10n, provider.errorMessage),
            onRetry: () => provider.initialize(widget.args),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  l10n.cronjobFormBasicSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CronjobFormBasicSectionWidget(
                  name: provider.draft.name,
                  groupLabel: _groupLabel(provider),
                  primaryType: provider.draft.primaryType,
                  onNameChanged: (value) => provider.updateBasic(name: value),
                  onPickGroup: () => _pickGroup(provider),
                  onPrimaryTypeChanged: (value) =>
                      provider.updateBasic(primaryType: value),
                  nameLabel: l10n.commonName,
                  groupLabelText: l10n.commandsGroupFieldLabel,
                  typeLabel: l10n.cronjobFormTypeLabel,
                  shellLabel: l10n.cronjobsTypeShell,
                  urlLabel: l10n.cronjobFormUrlTypeLabel,
                  backupLabel: l10n.operationsBackupsTitle,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.cronjobFormScheduleSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CronjobFormScheduleSectionWidget(
                  useRawSpec: provider.draft.useRawSpec,
                  rawSpecs: provider.draft.rawSpecs,
                  schedule: provider.draft.schedule,
                  isPreviewLoading: provider.isPreviewLoading,
                  previewItems: provider.nextPreview,
                  onToggleRawSpec: provider.updateScheduleMode,
                  onRawSpecChanged: provider.updateRawSpecAt,
                  onAddRawSpec: provider.addRawSpec,
                  onRemoveRawSpec: provider.removeRawSpec,
                  onScheduleChanged: provider.updateScheduleBuilder,
                  onPreview: provider.previewNext,
                  customSpecLabel: l10n.cronjobFormCustomSpecLabel,
                  previewLabel: l10n.cronjobFormPreviewAction,
                  builderModeLabel: l10n.cronjobFormBuilderModeLabel,
                  rawModeLabel: l10n.cronjobFormRawModeLabel,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.cronjobFormTargetSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (provider.draft.primaryType == 'shell')
                  CronjobFormShellTargetSectionWidget(
                    executor: provider.draft.executor,
                    user: provider.draft.user,
                    scriptMode: provider.draft.scriptMode,
                    script: provider.draft.script,
                    scriptID: provider.draft.scriptID,
                    scriptOptions: provider.scriptOptions,
                    onExecutorChanged: (value) =>
                        provider.updateShell(executor: value),
                    onUserChanged: (value) => provider.updateShell(user: value),
                    onScriptModeChanged: (value) => provider.updateShell(
                      scriptMode: value,
                      clearScriptId: value != 'library',
                      script: '',
                    ),
                    onScriptChanged: (value) =>
                        provider.updateShell(script: value),
                    onScriptIdChanged: (value) =>
                        provider.updateShell(scriptID: value),
                  ),
                if (provider.draft.primaryType == 'curl')
                  CronjobFormUrlTargetSectionWidget(
                    urlItems: provider.draft.urlItems,
                    onChanged: provider.updateUrlItems,
                  ),
                if (provider.draft.primaryType == 'backup')
                  CronjobFormBackupTargetSectionWidget(
                    backupType: provider.draft.backupType,
                    backupOptions: provider.backupOptions,
                    appOptions: provider.appOptions,
                    websiteOptions: provider.websiteOptions,
                    databaseType: provider.draft.dbType,
                    databaseItems: provider.databaseItems,
                    selectedAppIds: provider.draft.appIdList,
                    selectedWebsiteIds: provider.draft.websiteList,
                    selectedDatabaseIds: provider.draft.dbNameList,
                    isDir: provider.draft.isDir,
                    sourceDir: provider.draft.sourceDir,
                    files: provider.draft.files,
                    ignoreFiles: provider.draft.ignoreFiles,
                    withImage: provider.draft.withImage,
                    ignoreAppIDs: provider.draft.ignoreAppIDs,
                    sourceAccountItems: provider.draft.sourceAccountItems,
                    downloadAccountID: provider.draft.downloadAccountID,
                    secret: provider.draft.secret,
                    argItems: provider.draft.argItems,
                    onBackupTypeChanged: provider.updateBackupType,
                    onAppIdsChanged: provider.updateAppIds,
                    onWebsiteIdsChanged: provider.updateWebsiteIds,
                    onDatabaseTypeChanged: provider.updateDatabaseType,
                    onDatabaseIdsChanged: provider.updateDatabaseIds,
                    onDirectoryChanged: provider.updateDirectory,
                    onSnapshotChanged: provider.updateSnapshot,
                    onAccountsChanged: provider.updateBackupAccounts,
                    onPolicyChanged: ({secret, argItems}) =>
                        provider.updatePolicy(
                      secret: secret,
                      argItems: argItems,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.cronjobFormPolicySectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CronjobFormPolicySectionWidget(
                  retainCopies: provider.draft.retainCopies,
                  retryTimes: provider.draft.retryTimes,
                  timeoutValue: provider.draft.timeoutValue,
                  timeoutUnit: provider.draft.timeoutUnit,
                  ignoreErr: provider.draft.ignoreErr,
                  alertEnabled: provider.draft.alertEnabled,
                  alertCount: provider.draft.alertCount,
                  alertMethods: provider.draft.alertMethods,
                  argItems: provider.draft.primaryType == 'backup'
                      ? const <String>[]
                      : provider.draft.argItems,
                  onChanged: provider.updatePolicy,
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          floatingActionButton: null,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: provider.canSave ? _save : null,
              child: provider.isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ),
        );
      },
    );
  }

  String _groupLabel(CronjobFormProvider provider) {
    for (final group in provider.groups) {
      if (group.id == provider.draft.groupID) {
        final name = group.name?.trim();
        return name == null || name.isEmpty
            ? context.l10n.operationsGroupDefaultLabel
            : name;
      }
    }
    return context.l10n.operationsGroupDefaultLabel;
  }

  Future<void> _pickGroup(CronjobFormProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'cronjob',
      initialSelectedGroupId: provider.draft.groupID,
    );
    if (groupId != null) {
      provider.updateBasic(groupID: groupId);
    }
  }

  Future<void> _save() async {
    final success = await context.read<CronjobFormProvider>().save();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizeCronjobFormError(
                context.l10n,
                context.read<CronjobFormProvider>().errorMessage,
              ) ??
              context.l10n.commonSaveFailed,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.cronjobFormDeleteConfirm,
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await context.read<CronjobFormProvider>().delete();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    }
  }
}
