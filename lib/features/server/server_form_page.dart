import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/browser_connection_policy.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';
import 'panels/panel_credential_fields.dart';
import 'panels/panel_presentation.dart';
import 'server_connection_service.dart';

class ServerFormPage extends StatefulWidget {
  const ServerFormPage({super.key, this.existing});

  final ApiConfig? existing;

  @override
  State<ServerFormPage> createState() => _ServerFormPageState();
}

class _ServerFormPageState extends State<ServerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _tokenValidityController = TextEditingController(text: '0');
  final _connectionService = ServerConnectionService();
  late final _serverId =
      widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

  bool _saving = false;
  bool _testing = false;
  bool _allowInsecureTls = false;
  int _formVersion = 0;
  String? _confirmedHttpUrl;
  String _panelType = ApiConfig.onePanelType;
  final _additionalCredentials = <String, String>{};

  @override
  void initState() {
    super.initState();
    final original = widget.existing;
    if (original == null) return;
    _panelType = original.panelType;
    _nameController.text = original.name;
    _urlController.text = original.url;
    _tokenValidityController.text = original.tokenValidity.toString();
    _allowInsecureTls = original.allowInsecureTls;
  }

  ApiConfig? get _credentialSource {
    final original = widget.existing;
    return original != null &&
            original.panelType == _panelType &&
            original.url == _urlController.text.trim()
        ? original
        : null;
  }

  ApiConfig _readConfig() {
    final original = widget.existing;
    final source = _credentialSource;
    final typedKey = _apiKeyController.text.trim();
    return ApiConfig(
      id: _serverId,
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      panelType: _panelType,
      apiKey: typedKey.isNotEmpty ? typedKey : source?.apiKey ?? '',
      additionalCredentials: {
        ...?source?.additionalCredentials,
        for (final field in _additionalCredentials.entries)
          if (field.value.isNotEmpty) field.key: field.value,
      },
      tokenValidity: _panelType == ApiConfig.onePanelType
          ? int.tryParse(_tokenValidityController.text.trim()) ?? 0
          : original?.tokenValidity ?? 0,
      allowInsecureTls: _allowInsecureTls,
      isDefault: original?.isDefault ?? false,
      lastUsed: original?.lastUsed,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    _tokenValidityController.dispose();
    super.dispose();
  }

  Future<bool> _confirmHttpConnection() async {
    final address = _urlController.text.trim();
    if (!kIsWeb ||
        Uri.tryParse(address)?.scheme != 'http' ||
        _confirmedHttpUrl == address) {
      return true;
    }
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.webHttpConnectionTitle,
      message: l10n.webHttpConnectionWarning,
      confirmLabel: l10n.webHttpConnectionContinue,
    );
    if (confirmed) _confirmedHttpUrl = address;
    return confirmed;
  }

  String _connectionErrorMessage(ServerConnectionResult result) {
    return kIsWeb && result.isNetworkError
        ? context.l10n.webConnectionFailed
        : result.errorMessage ?? context.l10n.serverTestFailed;
  }

  Future<void> _testConnection() async {
    if (_testing || _saving || !_formKey.currentState!.validate()) return;
    final version = _formVersion;
    final config = _readConfig();
    setState(() => _testing = true);

    try {
      if (!await _confirmHttpConnection() || !mounted || version != _formVersion) {
        return;
      }
      final result = await _connectionService.testConfig(config);

      if (!mounted || version != _formVersion) return;

      if (result.success) {
        SnackBarUtils.showSuccess(context, [
          context.l10n.serverTestSuccess,
          if (result.operatingSystem != null) result.operatingSystem!,
          if (result.responseTime != null) '${result.responseTime!.inMilliseconds} ms',
        ].join(' · '));
      } else {
        SnackBarUtils.showError(context,
            '${context.l10n.serverTestFailed}: ${_connectionErrorMessage(result)}');
      }
    } catch (_) {
      if (mounted && version == _formVersion) {
        SnackBarUtils.showError(context, context.l10n.serverTestFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final version = ++_formVersion;
    final config = _readConfig();
    final l10n = context.l10n;
    final servers = context.read<ServerProvider>();
    setState(() {
      _saving = true;
    });

    try {
      if (!await _confirmHttpConnection() || !mounted || version != _formVersion) {
        return;
      }
      final original = widget.existing;
      if (original == null) {
        await servers.save(config);
      } else {
        await servers.updateConfig(config, expected: original);
      }
      if (!mounted) {
        return;
      }

      SnackBarUtils.showSuccess(context, l10n.serverFormSaveSuccess);
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context, true);
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) {
        return;
      }

      SnackBarUtils.showError(
        context,
        l10n.serverFormSaveFailed(
          e is StateError ? e.message : l10n.serverFormStorageError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final panels = PanelPresentations.entries;
    final panel = panels[_panelType];
    if (panel == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serverFormEditTitle)),
        body: ModuleErrorStateWidget(message: l10n.serverPanelUnavailable(_panelType)),
      );
    }

    return AppFormScaffold(
      title: widget.existing == null ? l10n.serverFormTitle : l10n.serverFormEditTitle,
      isSaving: _saving,
      onSave: _save,
      body: SingleChildScrollView(
        padding: AppDesignTokens.pagePadding,
        child: Form(
          canPop: !_saving,
          key: _formKey,
          onChanged: () => _formVersion++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                title: l10n.serverFormBasicSectionTitle,
                child: Column(
                  children: [
                    if (panels.length > 1) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _panelType,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l10n.serverPanelType),
                        items: [
                          for (final entry in panels.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value.name, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: widget.existing != null || _saving ? null : (type) {
                          if (type == null || type == _panelType) return;
                          setState(() {
                            _panelType = type;
                            _formVersion++;
                            _allowInsecureTls = false;
                            _tokenValidityController.text = '0';
                            _apiKeyController.clear();
                            _additionalCredentials.clear();
                          });
                        },
                      ),
                      const SizedBox(height: AppDesignTokens.spacingLg),
                    ],
                    TextFormField(
                      enabled: !_saving,
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.serverFormName,
                        hintText: l10n.serverFormNameHint,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? l10n.serverFormRequired
                              : null,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    TextFormField(
                      enabled: !_saving,
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      onChanged: widget.existing == null ? null : (_) => setState(() {}),
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.serverFormUrl,
                        hintText: l10n.serverFormUrlHint,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.serverFormRequired;
                        }
                        if (kIsWeb && BrowserConnectionPolicy.issue(value) != null) {
                          return l10n.webConnectionAddressInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    PanelCredentialFields(
                      key: ValueKey(_panelType),
                      panel: panel,
                      apiKeyController: _apiKeyController,
                      enabled: !_saving,
                      hasStoredApiKey: _credentialSource?.apiKey.isNotEmpty == true,
                      storedFields: {
                        for (final entry in _credentialSource?.additionalCredentials.entries ??
                            const <MapEntry<String, String>>[])
                          if (entry.value.isNotEmpty) entry.key,
                      },
                      onFieldChanged: (id, value) => _additionalCredentials[id] = value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              SectionCard(
                padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
                title: l10n.serverFormConnectionSectionTitle,
                child: Column(
                  children: [
                    if (_panelType == ApiConfig.onePanelType) TextFormField(
                      enabled: !_saving,
                      controller: _tokenValidityController,
                      decoration: InputDecoration(
                        labelText: l10n.serverTokenValidity,
                        hintText: l10n.serverTokenValidityHint,
                        suffixText: l10n.serverFormMinutes,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    if (kIsWeb) Text(l10n.webConnectionRequirements),
                    if (!kIsWeb) SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _allowInsecureTls,
                      onChanged: _saving ? null : (value) {
                        setState(() {
                          _allowInsecureTls = value;
                          _formVersion++;
                        });
                      },
                      title: Text(l10n.serverFormAllowInsecureTls),
                      subtitle: Text(l10n.serverFormAllowInsecureTlsHint),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _testing || _saving ? null : _testConnection,
                        child: _testing
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppDesignTokens.spacingSm,
                                children: [
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  Text(l10n.serverTestTesting),
                                ],
                              )
                            : Text(l10n.serverFormTest),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
