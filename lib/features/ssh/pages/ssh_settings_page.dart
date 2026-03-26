import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_settings_provider.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_raw_file_editor_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_section_nav_widget.dart';
import 'package:onepanel_client/features/ssh/widgets/ssh_settings_status_card_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class SshSettingsPage extends StatefulWidget {
  const SshSettingsPage({super.key});

  @override
  State<SshSettingsPage> createState() => _SshSettingsPageState();
}

class _SshSettingsPageState extends State<SshSettingsPage> {
  final TextEditingController _rawFileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) return;
      context.read<SshSettingsProvider>().load();
    });
  }

  @override
  void dispose() {
    _rawFileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<SshSettingsProvider>(
      builder: (context, provider, _) {
        if (_rawFileController.text != provider.rawConfig) {
          _rawFileController.text = provider.rawConfig;
        }
        final info = provider.info;
        return ServerAwarePageScaffold(
          title: l10n.operationsSshTitle,
          onServerChanged: () => context.read<SshSettingsProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SshSectionNavWidget(currentRoute: '/ssh'),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: info == null && !provider.hasError,
                  errorMessage: provider.errorMessage,
                  onRetry: provider.load,
                  emptyTitle: l10n.commonEmpty,
                  emptyDescription: l10n.commonLoadFailedTitle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      if (info != null)
                        SshSettingsStatusCardWidget(
                          info: info,
                          isBusy: provider.isMutating,
                          onOperate: _confirmOperate,
                          onToggleAutoStart: _confirmToggleAutoStart,
                        ),
                      if (info != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildSettingCard(context, info),
                        const SizedBox(height: 12),
                        SshRawFileEditorWidget(
                          controller: _rawFileController,
                          isBusy: provider.isMutating,
                          onReload: provider.reloadRawConfig,
                          onCopy: _copyRawConfig,
                          onSave: _confirmSaveRawFile,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingCard(BuildContext context, SshInfo info) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.sshSettingsNetworkSectionTitle,
                style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshPortLabel),
              subtitle: Text(info.port),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editSetting(
                label: l10n.sshPortLabel,
                key: 'Port',
                currentValue: info.port,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshListenAddressLabel),
              subtitle: Text(info.listenAddress),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editSetting(
                label: l10n.sshListenAddressLabel,
                key: 'ListenAddress',
                currentValue: info.listenAddress,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshPermitRootLoginLabel),
              subtitle: Text(info.permitRootLogin),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editSetting(
                label: l10n.sshPermitRootLoginLabel,
                key: 'PermitRootLogin',
                currentValue: info.permitRootLogin,
              ),
            ),
            const Divider(),
            Text(l10n.sshSettingsAuthenticationSectionTitle,
                style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshPasswordAuthenticationLabel),
              value: info.passwordAuthentication == 'yes',
              onChanged: (value) => _confirmToggleSetting(
                label: l10n.sshPasswordAuthenticationLabel,
                key: 'PasswordAuthentication',
                oldValue: info.passwordAuthentication,
                newValue: value ? 'yes' : 'no',
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshPubkeyAuthenticationLabel),
              value: info.pubkeyAuthentication == 'yes',
              onChanged: (value) => _confirmToggleSetting(
                label: l10n.sshPubkeyAuthenticationLabel,
                key: 'PubkeyAuthentication',
                oldValue: info.pubkeyAuthentication,
                newValue: value ? 'yes' : 'no',
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sshUseDnsLabel),
              value: info.useDNS == 'yes',
              onChanged: (value) => _confirmToggleSetting(
                label: l10n.sshUseDnsLabel,
                key: 'UseDNS',
                oldValue: info.useDNS,
                newValue: value ? 'yes' : 'no',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOperate(String operation) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.operationsSshTitle,
      message: l10n.sshOperateConfirm(operation),
      confirmLabel: l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshSettingsProvider>().operate(operation);
  }

  Future<void> _confirmToggleAutoStart(bool enabled) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.operationsSshTitle,
      message: context.l10n.sshOperateConfirm(enabled ? 'enable' : 'disable'),
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshSettingsProvider>().toggleAutoStart(enabled);
  }

  Future<void> _confirmToggleSetting({
    required String label,
    required String key,
    required String oldValue,
    required String newValue,
  }) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: label,
      message: context.l10n.sshUpdateSettingConfirm(label, newValue),
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshSettingsProvider>().updateSetting(
          key: key,
          oldValue: oldValue,
          newValue: newValue,
        );
  }

  Future<void> _editSetting({
    required String label,
    required String key,
    required String currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: controller),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: Text(context.l10n.commonConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || newValue == null || newValue == currentValue) return;
    await _confirmToggleSetting(
      label: label,
      key: key,
      oldValue: currentValue,
      newValue: newValue,
    );
  }

  Future<void> _copyRawConfig() async {
    await Clipboard.setData(ClipboardData(text: _rawFileController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonCopySuccess)),
    );
  }

  Future<void> _confirmSaveRawFile() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.sshSettingsRawFileSectionTitle,
      message: context.l10n.sshSaveRawFileConfirm,
      confirmLabel: context.l10n.commonSave,
    );
    if (!confirmed || !mounted) return;
    await context.read<SshSettingsProvider>().saveRawConfig(_rawFileController.text);
  }
}
