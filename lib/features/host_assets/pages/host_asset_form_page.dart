import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_form_args.dart';
import 'package:onepanel_client/features/host_assets/providers/host_asset_form_provider.dart';
import 'package:onepanel_client/features/host_assets/widgets/host_asset_form_auth_section_widget.dart';
import 'package:onepanel_client/features/host_assets/widgets/host_asset_form_basic_section_widget.dart';
import 'package:onepanel_client/features/host_assets/widgets/host_asset_form_connection_section_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class HostAssetFormPage extends StatefulWidget {
  const HostAssetFormPage({
    super.key,
    this.args,
  });

  final HostAssetFormArgs? args;

  @override
  State<HostAssetFormPage> createState() => _HostAssetFormPageState();
}

class _HostAssetFormPageState extends State<HostAssetFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _addrController;
  late final TextEditingController _portController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _passPhraseController;

  @override
  void initState() {
    super.initState();
    final initial = widget.args?.initialValue;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _addrController = TextEditingController(text: initial?.addr ?? '');
    _portController =
        TextEditingController(text: (initial?.port ?? 22).toString());
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _userController = TextEditingController(text: initial?.user ?? 'root');
    _passwordController =
        TextEditingController(text: initial?.password ?? '');
    _privateKeyController =
        TextEditingController(text: initial?.privateKey ?? '');
    _passPhraseController =
        TextEditingController(text: initial?.passPhrase ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addrController.dispose();
    _portController.dispose();
    _descriptionController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passPhraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HostAssetFormProvider>(
      builder: (context, provider, _) {
        final l10n = context.l10n;
        return ServerAwarePageScaffold(
          title: provider.isEditing
              ? l10n.hostAssetsEditTitle
              : l10n.hostAssetsCreateTitle,
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: provider.errorMessage,
            onRetry: () => provider.initialize(widget.args),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  l10n.hostAssetsBasicSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                HostAssetFormBasicSectionWidget(
                  nameController: _nameController,
                  addrController: _addrController,
                  portController: _portController,
                  descriptionController: _descriptionController,
                  groupLabel: _groupLabel(provider),
                  onPickGroup: () => _pickGroup(provider),
                  onNameChanged: (value) => provider.updateBasic(name: value),
                  onAddrChanged: (value) => provider.updateBasic(addr: value),
                  onPortChanged: (value) => provider.updateBasic(
                    port: int.tryParse(value) ?? 22,
                  ),
                  onDescriptionChanged: (value) =>
                      provider.updateBasic(description: value),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.hostAssetsAuthSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                HostAssetFormAuthSectionWidget(
                  userController: _userController,
                  passwordController: _passwordController,
                  privateKeyController: _privateKeyController,
                  passPhraseController: _passPhraseController,
                  authMode: provider.draft.authMode,
                  rememberPassword: provider.draft.rememberPassword,
                  onUserChanged: (value) => provider.updateAuth(user: value),
                  onAuthModeChanged: (value) => provider.updateAuth(
                    authMode: value,
                    password: value == 'password' ? _passwordController.text : '',
                    privateKey:
                        value == 'key' ? _privateKeyController.text : '',
                    passPhrase:
                        value == 'key' ? _passPhraseController.text : '',
                  ),
                  onPasswordChanged: (value) =>
                      provider.updateAuth(password: value),
                  onPrivateKeyChanged: (value) =>
                      provider.updateAuth(privateKey: value),
                  onPassPhraseChanged: (value) =>
                      provider.updateAuth(passPhrase: value),
                  onRememberPasswordChanged: (value) =>
                      provider.updateAuth(rememberPassword: value),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.hostAssetsConnectionSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                HostAssetFormConnectionSectionWidget(
                  isTesting: provider.isTesting,
                  isVerified: provider.isConnectionVerified,
                  testMessage: _testMessage(provider),
                  onTest: _testConnection,
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

  String _groupLabel(HostAssetFormProvider provider) {
    String? name;
    for (final group in provider.groups) {
      if (group.id == provider.draft.groupID) {
        name = group.name;
        break;
      }
    }
    return name == null || name.trim().isEmpty
        ? context.l10n.operationsGroupDefaultLabel
        : name;
  }

  String _testMessage(HostAssetFormProvider provider) {
    if (provider.isConnectionVerified) {
      return context.l10n.hostAssetsConnectionVerified;
    }
    if (provider.testMessage?.isNotEmpty == true &&
        provider.testMessage != 'failed') {
      return provider.testMessage!;
    }
    if (provider.testMessage == 'failed') {
      return context.l10n.hostAssetsTestFailed;
    }
    return context.l10n.hostAssetsConnectionNeedsTest;
  }

  Future<void> _pickGroup(HostAssetFormProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'host',
      initialSelectedGroupId: provider.draft.groupID,
    );
    if (groupId != null) {
      provider.updateBasic(groupID: groupId);
    }
  }

  Future<void> _testConnection() async {
    await context.read<HostAssetFormProvider>().testConnection();
  }

  Future<void> _save() async {
    final success = await context.read<HostAssetFormProvider>().save();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<HostAssetFormProvider>().errorMessage ??
              context.l10n.commonSaveFailed,
        ),
      ),
    );
  }
}
