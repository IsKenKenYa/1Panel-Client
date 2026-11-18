import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class ApiKeySettingsPage extends StatelessWidget {
  const ApiKeySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<SettingsProvider>();
    final settings = provider.data.systemSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.apiKeySettingsTitle)),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          SectionCard(
            title: l10n.apiKeySettingsStatus,
            child: SwitchListTile(
              secondary: const Icon(Icons.key_outlined),
              title: Text(l10n.apiKeySettingsEnabled),
              subtitle: Text(
                _isEnabled(settings?.apiInterfaceStatus)
                    ? l10n.systemSettingsEnabled
                    : l10n.systemSettingsDisabled,
              ),
              value: _isEnabled(settings?.apiInterfaceStatus),
              onChanged: (value) =>
                  _toggleApiKey(context, provider, l10n, value),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            title: l10n.apiKeySettingsInfo,
            items: [
              SectionEntryItem(
                icon: Icons.vpn_key_outlined,
                title: l10n.apiKeySettingsKey,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings?.apiKey ?? '-',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: context.l10n.commonCopy,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: settings?.apiKey ?? ''));
                        SnackBarUtils.showSuccess(
                            context, context.l10n.commonCopied);
                      },
                    ),
                  ],
                ),
              ),
              SectionEntryItem(
                icon: Icons.list_alt_outlined,
                title: l10n.apiKeySettingsIpWhitelist,
                trailing: Text(
                  settings?.ipWhiteList ?? '-',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              SectionEntryItem(
                icon: Icons.timer_outlined,
                title: l10n.apiKeySettingsValidityTime,
                trailing: Text(
                  settings?.apiKeyValidityTime ?? '-',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            title: l10n.apiKeySettingsActions,
            items: [
              SectionEntryItem(
                icon: Icons.refresh_outlined,
                title: l10n.apiKeySettingsRegenerate,
                subtitle: l10n.apiKeySettingsRegenerateDesc,
                onTap: () => _regenerateApiKey(context, provider, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isEnabled(String? value) {
    if (value == null) return false;
    return value.toLowerCase() == 'enable' || value.toLowerCase() == 'true';
  }

  void _toggleApiKey(BuildContext context, SettingsProvider provider,
      AppLocalizations l10n, bool enable) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: enable ? l10n.apiKeySettingsEnable : l10n.apiKeySettingsDisable,
      message: enable
          ? l10n.apiKeySettingsEnableConfirm
          : l10n.apiKeySettingsDisableConfirm,
      confirmLabel: l10n.commonConfirm,
    );

    if (confirmed == true && context.mounted) {
      final validityTimeStr =
          provider.data.systemSettings?.apiKeyValidityTime ?? '0';
      final validityTimeInt = int.tryParse(validityTimeStr) ?? 0;
      final success = await provider.updateApiConfig(
        status: enable ? 'Enable' : 'Disable',
        ipWhiteList: provider.data.systemSettings?.ipWhiteList ?? '0.0.0.0/0',
        validityTime: validityTimeInt,
      );
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, l10n.commonSaveSuccess);
        } else {
          SnackBarUtils.showError(context, l10n.commonSaveFailed);
        }
      }
    }
  }

  void _regenerateApiKey(BuildContext context, SettingsProvider provider,
      AppLocalizations l10n) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.apiKeySettingsRegenerate,
      message: l10n.apiKeySettingsRegenerateConfirm,
      confirmLabel: l10n.commonConfirm,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.generateApiKey();
      if (context.mounted) {
        if (success) {
          SnackBarUtils.showSuccess(
              context, l10n.apiKeySettingsRegenerateSuccess);
        } else {
          SnackBarUtils.showError(context, l10n.commonSaveFailed);
        }
      }
    }
  }
}
