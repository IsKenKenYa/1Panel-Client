import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/widgets/settings_save_action.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.select(
        (AppSettingsController settings) => settings.locale?.languageCode);
    return SettingsScaffold(
      title: l10n.settingsLanguage,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          SectionCard(
            child: RadioGroup<String>(
              groupValue: language ?? 'system',
              onChanged: (value) {
                if (value == null) return;
                saveAppPreference(
                  context,
                  () => context.read<AppSettingsController>().updateLocale(
                        value == 'system' ? null : Locale(value),
                      ),
                );
              },
              child: Column(
                children: [
                  RadioListTile(
                    value: 'system',
                    title: Text(l10n.languageSystem),
                  ),
                  RadioListTile(value: 'zh', title: Text(l10n.languageZh)),
                  RadioListTile(value: 'en', title: Text(l10n.languageEn)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
