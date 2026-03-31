import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLanguage),
      ),
      body: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          final value = settings.locale?.languageCode ?? 'system';
          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              Text(
                l10n.settingsLanguageHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              Card(
                child: Column(
                  children: [
                    _LanguageOptionTile(
                      icon: Icons.phone_android_outlined,
                      label: l10n.languageSystem,
                      selected: value == 'system',
                      onTap: () => settings.updateLocale(null),
                    ),
                    const Divider(height: 1),
                    _LanguageOptionTile(
                      icon: Icons.translate_outlined,
                      label: l10n.languageZh,
                      selected: value == 'zh',
                      onTap: () => settings.updateLocale(const Locale('zh')),
                    ),
                    const Divider(height: 1),
                    _LanguageOptionTile(
                      icon: Icons.language_outlined,
                      label: l10n.languageEn,
                      selected: value == 'en',
                      onTap: () => settings.updateLocale(const Locale('en')),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
