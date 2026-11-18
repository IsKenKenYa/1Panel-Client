import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({super.key});

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _enabled = false;
  bool _saving = false;
  String _proxyType = 'http';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final provider = context.read<SettingsProvider>();
    final settings = provider.data.systemSettings;
    if (settings != null) {
      setState(() {
        _enabled = settings.proxyUrl != null && settings.proxyUrl!.isNotEmpty;
        // 服务端未配置代理时 proxyType 可能是空串或未知值（非 null），
        // 必须做白名单校验回退默认值，否则 DropdownButton value 不在 items
        // 中会触发 "exactly one item with value" 断言崩溃。
        _proxyType = settings.proxyType == 'https' ? 'https' : 'http';
        _hostController.text = settings.proxyUrl ?? '';
        _portController.text = settings.proxyPort ?? '';
        _userController.text = settings.proxyUser ?? '';
        _passwordController.text = settings.proxyPasswd ?? '';
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormScaffold(
      title: l10n.proxySettingsTitle,
      isSaving: _saving,
      onSave: _saveSettings,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppDesignTokens.pagePadding,
          children: [
            SectionCard(
              child: SwitchListTile(
                secondary: const Icon(Icons.vpn_lock_outlined),
                title: Text(l10n.proxySettingsEnable),
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            SectionCard(
              title: l10n.proxySettingsTitle,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(l10n.proxySettingsType),
                    trailing: DropdownButton<String>(
                      value: _proxyType,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                            value: 'http', child: Text(l10n.proxySettingsHttp)),
                        DropdownMenuItem(
                            value: 'https',
                            child: Text(l10n.proxySettingsHttps)),
                      ],
                      onChanged: _enabled
                          ? (value) {
                              setState(() {
                                _proxyType = value ?? 'http';
                              });
                            }
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        labelText: l10n.proxySettingsHost,
                        prefixIcon: const Icon(Icons.dns_outlined),
                      ),
                      enabled: _enabled,
                      validator: (value) {
                        if (_enabled && (value == null || value.isEmpty)) {
                          return l10n.proxySettingsHost;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: l10n.proxySettingsPort,
                        prefixIcon: const Icon(Icons.numbers_outlined),
                      ),
                      enabled: _enabled,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_enabled && (value == null || value.isEmpty)) {
                          return l10n.proxySettingsPort;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: l10n.proxySettingsUser,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      enabled: _enabled,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.proxySettingsPassword,
                        prefixIcon: const Icon(Icons.lock_outlined),
                      ),
                      enabled: _enabled,
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final provider = context.read<SettingsProvider>();
    final l10n = context.l10n;

    final success = await provider.updateProxySettings(
      proxyUrl: _hostController.text,
      proxyPort: int.tryParse(_portController.text),
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        SnackBarUtils.showSuccess(context, l10n.proxySettingsSaved);
      } else {
        SnackBarUtils.showError(context, l10n.proxySettingsFailed);
      }
    }
  }
}
