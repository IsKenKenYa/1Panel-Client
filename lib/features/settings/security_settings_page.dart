import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_x.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import '../security/security_verification_page.dart';
import 'settings_provider.dart';
import 'widgets/settings_scaffold.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;
    final complexityEnabled = settings?.complexityVerification == 'Enable';

    SectionEntryItem editableSetting({
      required String title,
      required IconData icon,
      required String key,
      required String? value,
    }) {
      return SectionEntryItem(
        title: title,
        icon: icon,
        subtitle: key == 'SecurityEntrance' && value?.isNotEmpty == true
            ? l10n.systemSettingsEnabled
            : value,
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _edit(context, provider, key, title, value ?? ''),
      );
    }

    return SettingsScaffold(
      title: l10n.securitySettingsTitle,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          PanelAccountSettingsEntry(
            serverUrl: provider.serverUrl,
            securityEntrance: settings?.securityEntrance,
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            title: l10n.securitySettingsAccessControl,
            items: [
              editableSetting(
                title: l10n.securitySettingsSecurityEntrance,
                icon: Icons.login_outlined,
                key: 'SecurityEntrance',
                value: settings?.securityEntrance,
              ),
              editableSetting(
                title: l10n.securitySettingsBindDomain,
                icon: Icons.domain_outlined,
                key: 'BindDomain',
                value: settings?.bindDomain,
              ),
              editableSetting(
                title: l10n.securitySettingsAllowIPs,
                icon: Icons.list_alt_outlined,
                key: 'AllowIPs',
                value: settings?.allowIPs,
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionCard(
            title: l10n.securitySettingsPasswordPolicy,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.password_outlined),
                  title: Text(l10n.securitySettingsComplexityVerification),
                  value: complexityEnabled,
                  onChanged: (value) => _save(
                    context,
                    provider,
                    'ComplexityVerification',
                    value ? 'Enable' : 'Disable',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.securitySettingsExpirationDays),
                  subtitle: Text(settings?.expirationDays ?? '0'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _edit(
                    context,
                    provider,
                    'ExpirationDays',
                    l10n.securitySettingsExpirationDays,
                    settings?.expirationDays ?? '0',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    SettingsProvider provider,
    String key,
    String title,
    String initialValue, {
    TextInputType keyboard = TextInputType.text,
  }) async {
    final l10n = context.l10n;
    final result = await showAppTextInputDialog(
      context,
      title: title,
      initialValue: initialValue,
      keyboardType: keyboard,
      autofocus: false,
      allowEmpty: true,
      confirmLabel: l10n.commonSave,
    );
    if (result != null && result != initialValue && context.mounted) {
      await _save(context, provider, key, result);
    }
  }

  Future<void> _save(
    BuildContext context,
    SettingsProvider provider,
    String key,
    String value,
  ) async {
    final saved = await provider.updateSystemSetting(key, value);
    if (!context.mounted) return;
    if (saved) {
      SnackBarUtils.showSuccess(context, context.l10n.commonSaveSuccess);
    } else {
      SnackBarUtils.showError(
        context,
        provider.data.error ?? context.l10n.commonSaveFailed,
      );
    }
  }
}
