import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class FileExportSettingsSection extends StatefulWidget {
  const FileExportSettingsSection({super.key});

  @override
  State<FileExportSettingsSection> createState() => _FileExportSettingsSectionState();
}

class _FileExportSettingsSectionState extends State<FileExportSettingsSection> {
  final _preferences = AppPreferencesService();
  bool? _usePicker;
  String _folder = '';
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usePicker = await _preferences.loadUseFilePickerForFileOperations();
      final folder = await _preferences.loadFileSaveSubDirectoryName();
      if (!mounted) return;
      setState(() {
        _usePicker = usePicker;
        _folder = folder;
        _loadError = null;
      });
    } catch (error, stackTrace) {
      _logError(error, stackTrace);
      if (mounted) {
        setState(() => _loadError = ErrorMessageUtils.userFacingMessage(error));
      }
    }
  }

  void _logError(Object error, StackTrace stackTrace) {
    appLogger.eWithPackage(
      'features.settings.file_export',
      'File preferences failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _save(Future<void> Function() persist, VoidCallback apply) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await persist();
      if (mounted) setState(apply);
    } catch (error, stackTrace) {
      _logError(error, stackTrace);
      if (mounted) {
        SnackBarUtils.showError(context, ErrorMessageUtils.userFacingMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editFolder() async {
    final l10n = context.l10n;
    final form = GlobalKey<FormState>();
    var name = _folder;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AppFormDialog(
        title: l10n.systemSettingsFileExportSubDirTitle,
        confirmLabel: l10n.commonSave,
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: name,
            autofocus: true,
            decoration: InputDecoration(helperText: l10n.systemSettingsFileExportSubDirHelper, helperMaxLines: 3),
            onChanged: (value) => name = value.trim(),
            validator: (_) => isValidExportFolderName(name) ? null : l10n.settingsInvalidFolderName,
          ),
        ),
        onConfirm: () async {
          if (form.currentState!.validate()) Navigator.pop(context, name);
        },
      ),
    );
    if (!mounted || result == null || result == _folder) return;
    await _save(() => _preferences.saveFileSaveSubDirectoryName(result), () => _folder = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final usePicker = _usePicker;
    return SectionCard(
      title: l10n.systemSettingsFileExportSection,
      child: _loadError != null
          ? ModuleErrorStateWidget(message: _loadError, onRetry: _load)
          : usePicker == null
              ? const LinearProgressIndicator()
              : Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.folder_open_outlined),
                      title: Text(l10n.systemSettingsFileExportUsePicker),
                      subtitle: Text(l10n.systemSettingsFileExportUsePickerDesc),
                      value: usePicker,
                      onChanged: _saving ? null : (value) => _save(
                        () => _preferences.saveUseFilePickerForFileOperations(value),
                        () => _usePicker = value,
                      ),
                    ),
                    if (!usePicker) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.create_new_folder_outlined),
                        title: Text(l10n.systemSettingsFileExportSubDirTitle),
                        subtitle: Text(_folder.isEmpty ? l10n.systemSettingsFileExportSubDirHelper : _folder),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _saving ? null : _editFolder,
                      ),
                    ],
                  ],
                ),
    );
  }
}

bool isValidExportFolderName(String name) {
  if (name.isEmpty) return true;
  return !name.endsWith('.') &&
      !RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(name) &&
      !RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.|$)', caseSensitive: false).hasMatch(name);
}
