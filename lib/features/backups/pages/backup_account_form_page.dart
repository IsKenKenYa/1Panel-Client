import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_account_form_provider.dart';
import 'package:onepanel_client/features/backups/widgets/backup_account_form_basic_section_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_account_form_credentials_section_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_account_form_storage_section_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_account_form_verify_section_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class BackupAccountFormPage extends StatefulWidget {
  const BackupAccountFormPage({
    super.key,
    this.args,
  });

  final BackupAccountFormArgs? args;

  @override
  State<BackupAccountFormPage> createState() => _BackupAccountFormPageState();
}

class _BackupAccountFormPageState extends State<BackupAccountFormPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<BackupAccountFormProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<BackupAccountFormProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: provider.isEditing
              ? l10n.operationsBackupAccountFormTitle
              : l10n.operationsBackupAccountFormTitle,
          onServerChanged: () =>
              context.read<BackupAccountFormProvider>().initialize(widget.args),
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: provider.errorMessage,
            onRetry: () => provider.initialize(widget.args),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text('Basic', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BackupAccountFormBasicSectionWidget(
                  name: provider.draft.name,
                  isPublic: provider.draft.isPublic,
                  providerType: provider.draft.type,
                  providerTypes: provider.providerTypes,
                  onNameChanged: (value) => provider.updateBasic(name: value),
                  onPublicChanged: (value) =>
                      provider.updateBasic(isPublic: value),
                  onProviderChanged: provider.updateType,
                ),
                const SizedBox(height: 24),
                Text(
                  'Credentials',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                BackupAccountFormCredentialsSectionWidget(
                  draft: provider.draft,
                  onCommonChanged: provider.updateCommon,
                  onVarChanged: provider.updateVar,
                  onOneDriveRegionChanged: provider.updateOneDriveRegion,
                  onAliyunTokenChanged: provider.applyAliyunToken,
                  onStartOAuth: provider.startOAuth,
                ),
                const SizedBox(height: 24),
                Text('Storage', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BackupAccountFormStorageSectionWidget(
                  draft: provider.draft,
                  bucketOptions: provider.bucketOptions,
                  isLoadingBuckets: provider.isLoadingBuckets,
                  onCommonChanged: provider.updateCommon,
                  onVarChanged: provider.updateVar,
                  onLoadBuckets: provider.loadBuckets,
                ),
                const SizedBox(height: 24),
                Text('Verify', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BackupAccountFormVerifySectionWidget(
                  isTesting: provider.isTesting,
                  isVerified: provider.isConnectionVerified,
                  testMessage: provider.testMessage,
                  onTest: provider.testConnection,
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

  Future<void> _save() async {
    final success = await context.read<BackupAccountFormProvider>().save();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<BackupAccountFormProvider>().errorMessage ??
              context.l10n.commonSaveFailed,
        ),
      ),
    );
  }
}
