import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class MonitorSettingsPage extends StatefulWidget {
  const MonitorSettingsPage({super.key, required this.server, this.onChanged});

  final ApiConfig server;
  final VoidCallback? onChanged;

  static Future<void> open(BuildContext context) async {
    final server = context.read<CurrentServerController>().currentServer;
    if (server == null) {
      SnackBarUtils.showError(context, context.l10n.serverListEmptyTitle);
      return;
    }
    final monitor = context.read<MonitoringProvider?>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MonitorSettingsPage(
        server: server,
        onChanged: monitor?.invalidateMonitorSettings,
      ),
    ));
  }

  @override
  State<MonitorSettingsPage> createState() => _MonitorSettingsPageState();
}

class _MonitorSettingsPageState extends State<MonitorSettingsPage> {
  late final MonitoringProvider _provider;
  late Future<bool> _load;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _provider = MonitoringProvider.forSettings(widget.server);
    _load = _provider.loadSettings();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _save(Future<bool> Function() update) async {
    if (_busy) return;
    setState(() => _busy = true);
    final onChanged = widget.onChanged;
    final saved = await update();
    if (saved) onChanged?.call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (saved) _load = _provider.loadSettings(reloadDevices: false);
    });
    if (saved) {
      SnackBarUtils.showSuccess(context, context.l10n.monitorSettingsSaved);
    } else {
      SnackBarUtils.showError(context, ErrorMessageUtils.truncateForToast(
        _provider.data.error ?? context.l10n.monitorSettingsFailed,
      ));
    }
  }

  Future<void> _editNumber({required bool interval, required int? current}) async {
    final l10n = context.l10n;
    final form = GlobalKey<FormState>();
    int? edited = current;
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AppFormDialog(
        title: interval ? l10n.monitorSettingsInterval : l10n.monitorSettingsStoreDays,
        confirmLabel: l10n.commonSave,
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            initialValue: current?.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: interval ? l10n.monitorIntervalUnit : l10n.monitorRetentionUnit,
            ),
            validator: (raw) {
              edited = int.tryParse(raw?.trim() ?? '');
              if (interval) {
                return isValidMonitorInterval(edited) ? null : l10n.monitorIntervalValidation;
              }
              return edited != null && edited! > 0 ? null : l10n.monitorRetentionValidation;
            },
          ),
        ),
        onConfirm: () async {
          if (form.currentState!.validate()) Navigator.pop(dialogContext, edited);
        },
      ),
    );
    if (!mounted || value == null || value == current) return;
    await _save(() => interval
        ? _provider.updateSettings(interval: value)
        : _provider.updateSettings(retention: value));
  }

  Future<void> _chooseDevice({required bool disk, required String? current}) async {
    final l10n = context.l10n;
    final options = disk ? _provider.data.ioOptions : _provider.data.networkOptions;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(disk ? l10n.monitorIoDeviceLabel : l10n.monitorNetworkInterfaceLabel),
        children: [
          for (final option in options.toSet())
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, option),
              child: ListTile(
                title: Text(option == 'all' ? l10n.monitorAll : option),
                trailing: option == current ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
    if (!mounted || selected == null || selected == current) return;
    await _save(() => disk
        ? _provider.updateSettings(defaultIO: selected)
        : _provider.updateSettings(defaultNetwork: selected));
  }

  Future<void> _clean() async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.monitorCleanData,
      message: '${widget.server.name}\n${l10n.monitorCleanConfirm}',
      confirmLabel: l10n.commonClear,
      isDestructive: true,
    );
    if (!confirmed || !mounted || _busy) return;
    setState(() => _busy = true);
    final onChanged = widget.onChanged;
    final success = await _provider.cleanData();
    if (success) onChanged?.call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      SnackBarUtils.showSuccess(context, l10n.monitorCleanSuccess);
    } else {
      SnackBarUtils.showError(context, ErrorMessageUtils.truncateForToast(
        _provider.data.error ?? l10n.monitorCleanFailed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.monitorSettingsTitle)),
      body: FutureBuilder<bool>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != true) {
            return ModuleErrorStateWidget(
              message: _provider.data.error,
              onRetry: () => setState(() {
                _load = _provider.loadSettings();
              }),
            );
          }
          final settings = _provider.data.settings!;
          String deviceLabel(String? value) =>
              value == 'all' ? l10n.monitorAll : value ?? '—';
          return AdaptiveWidthContainer(
            maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
            child: ListView(
              padding: AppDesignTokens.pagePadding,
              children: [
                SectionCard(
                  title: widget.server.name,
                  child: SwitchListTile(
                    secondary: const Icon(Icons.monitor_heart_outlined),
                    title: Text(l10n.monitorSettingsEnable),
                    value: settings.enabled!,
                    onChanged: _busy ? null : (value) => _save(() => _provider.updateSettings(enabled: value)),
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionEntryList(items: [
                  SectionEntryItem(
                    icon: Icons.timer_outlined,
                    title: l10n.monitorSettingsInterval,
                    subtitle: settings.interval == null ? '—' : '${settings.interval} ${l10n.monitorIntervalUnit}',
                    onTap: _busy ? null : () => _editNumber(interval: true, current: settings.interval),
                  ),
                  SectionEntryItem(
                    icon: Icons.history_outlined,
                    title: l10n.monitorSettingsStoreDays,
                    subtitle: settings.retention == null ? '—' : '${settings.retention} ${l10n.monitorRetentionUnit}',
                    onTap: _busy ? null : () => _editNumber(interval: false, current: settings.retention),
                  ),
                  SectionEntryItem(
                    icon: Icons.storage_outlined,
                    title: l10n.monitorIoDeviceLabel,
                    subtitle: deviceLabel(settings.defaultIO),
                    onTap: _busy || _provider.data.ioOptions.isEmpty ? null : () => _chooseDevice(disk: true, current: settings.defaultIO),
                  ),
                  SectionEntryItem(
                    icon: Icons.lan_outlined,
                    title: l10n.monitorNetworkInterfaceLabel,
                    subtitle: deviceLabel(settings.defaultNetwork),
                    onTap: _busy || _provider.data.networkOptions.isEmpty ? null : () => _chooseDevice(disk: false, current: settings.defaultNetwork),
                  ),
                ]),
                const SizedBox(height: AppDesignTokens.spacingMd),
                SectionCard(
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    iconColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.error,
                    title: Text(l10n.monitorCleanData),
                    onTap: _busy ? null : _clean,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

bool isValidMonitorInterval(int? value) =>
    value != null && value >= 10 && value <= 43200;
