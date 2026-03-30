import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/about_page.dart';
import 'package:onepanel_client/features/settings/app_lock_settings_page.dart';
import 'package:onepanel_client/features/settings/screens/theme_settings_page.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/pages/settings/cache_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : buildShellDrawerLeading(
                context,
                key: const Key('shell-drawer-menu-button'),
              ),
        title: Text(l10n.settingsPageTitle),
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          Text(l10n.settingsGeneral,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Consumer<AppSettingsController>(
              builder: (context, settings, _) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.color_lens_outlined),
                      title: Text(l10n.settingsTheme),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemeSettingsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: AppDesignTokens.pagePadding,
                      child: _LanguageSelector(settings: settings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_person_outlined),
                      title: Text(l10n.settingsAppLock),
                      subtitle: Text(l10n.settingsAppLockDesc),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppLockSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.settingsStorage,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cached_outlined),
                  title: Text(l10n.settingsCacheTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CacheSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.settingsSystem,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(l10n.settingsServerManagement),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/server'),
                ),
                ListTile(
                  leading: const Icon(Icons.slideshow_outlined),
                  title: Text(l10n.settingsResetOnboarding),
                  onTap: () async {
                    await OnboardingService().resetAll();
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsResetOnboardingDone)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(l10n.settingsFeedback),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openFeedback(context),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsAbout),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openFeedback(BuildContext context) async {
  final ok = await launchUrl(
    Uri.parse(AboutPage.issuesUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsFeedbackOpenFailed)),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = settings.locale?.languageCode ?? 'system';

    return Row(
      children: [
        Expanded(child: Text(l10n.settingsLanguage)),
        DropdownButton<String>(
          value: value,
          onChanged: (next) {
            switch (next) {
              case 'zh':
                settings.updateLocale(const Locale('zh'));
                break;
              case 'en':
                settings.updateLocale(const Locale('en'));
                break;
              default:
                settings.updateLocale(null);
            }
          },
          items: [
            DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
            DropdownMenuItem(value: 'zh', child: Text(l10n.languageZh)),
            DropdownMenuItem(value: 'en', child: Text(l10n.languageEn)),
          ],
        ),
      ],
    );
  }
}
