import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';

/// 模型下载设置抽屉：模型目录、HF/ModelScope 地址与令牌、自动同步。
class ModelDownloaderSettingsSheet extends StatefulWidget {
  const ModelDownloaderSettingsSheet({super.key});

  @override
  State<ModelDownloaderSettingsSheet> createState() =>
      _ModelDownloaderSettingsSheetState();
}

class _ModelDownloaderSettingsSheetState
    extends State<ModelDownloaderSettingsSheet> {
  final _modelDirController = TextEditingController();
  final _hfEndpointController = TextEditingController();
  final _hfTokenController = TextEditingController();
  final _modelScopeEndpointController = TextEditingController();
  final _modelScopeTokenController = TextEditingController();

  bool _autoSync = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<ModelDownloaderProvider>();
    await provider.loadSettings();
    if (!mounted) return;
    final settings = provider.settings;
    setState(() {
      _modelDirController.text = settings.modelDir;
      _hfEndpointController.text = settings.hfEndpoint ?? '';
      _hfTokenController.text = settings.hfToken ?? '';
      _modelScopeEndpointController.text = settings.modelScopeEndpoint ?? '';
      _modelScopeTokenController.text = settings.modelScopeToken ?? '';
      _autoSync = settings.featuredModelsSync != 'Disable';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _modelDirController.dispose();
    _hfEndpointController.dispose();
    _hfTokenController.dispose();
    _modelScopeEndpointController.dispose();
    _modelScopeTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ModelDownloaderProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.modelDownloaderSettingsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_loaded && provider.settingsLoading)
                const LinearProgressIndicator(minHeight: 2)
              else ...[
                TextField(
                  controller: _modelDirController,
                  decoration: InputDecoration(
                    labelText: l10n.modelDownloaderSettingsModelDirLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hfEndpointController,
                  decoration: InputDecoration(
                    labelText: l10n.modelDownloaderSettingsHfEndpointLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hfTokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.modelDownloaderSettingsHfTokenLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelScopeEndpointController,
                  decoration: InputDecoration(
                    labelText:
                        l10n.modelDownloaderSettingsModelScopeEndpointLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelScopeTokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        l10n.modelDownloaderSettingsModelScopeTokenLabel,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoSync,
                  title: Text(l10n.modelDownloaderSettingsFeaturedSyncLabel),
                  onChanged: (value) => setState(() => _autoSync = value),
                ),
                if (provider.settingsError != null)
                  Text(
                    provider.settingsError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.commonSave),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await context.read<ModelDownloaderProvider>().updateSettings(
            ModelDownloaderSetting(
              modelDir: _modelDirController.text.trim(),
              hfEndpoint: _emptyToNull(_hfEndpointController.text),
              hfToken: _emptyToNull(_hfTokenController.text),
              modelScopeEndpoint: _emptyToNull(_modelScopeEndpointController.text),
              modelScopeToken: _emptyToNull(_modelScopeTokenController.text),
              featuredModelsSync: _autoSync ? 'Enable' : 'Disable',
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(
          context, l10n.modelDownloaderSettingsSaveSuccess);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackBarUtils.showError(context, error.toString());
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
