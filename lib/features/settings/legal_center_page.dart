import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';

class LegalCenterPage extends StatelessWidget {
  const LegalCenterPage({super.key});

  static const String _repoRoot =
      'https://github.com/IsKenKenYa/1Panel-Client/blob/main';
  static const String _privacyPolicyZhUrl =
      '$_repoRoot/docs/PRIVACY_POLICY.zh-CN.md';
  static const String _privacyPolicyEnUrl = '$_repoRoot/docs/PRIVACY_POLICY.md';
  static const String _termsUrl = '$_repoRoot/docs/TERMS_OF_SERVICE.md';
  static const String _thirdPartyNoticesUrl =
      '$_repoRoot/THIRD_PARTY_LICENSES.md';
  static const String _openSourceLicenseUrl = '$_repoRoot/LICENSE';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final privacyUrl =
        locale.languageCode == 'zh' ? _privacyPolicyZhUrl : _privacyPolicyEnUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLegalCenterTitle),
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.settingsLegalCenterIntro),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.settingsLegalDocumentsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.settingsLegalPrivacyPolicy),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternal(context, privacyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l10n.settingsLegalTermsOfService),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternal(context, _termsUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.copyright_outlined),
                  title: Text(l10n.settingsLegalThirdPartyNotices),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternal(context, _thirdPartyNoticesUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.settingsLegalOpenSourceLicense),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openExternal(context, _openSourceLicenseUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: Text(l10n.settingsLegalFlutterPackages),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(
            l10n.settingsMainlandSdkDisclosureTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.developer_board_outlined),
              title: Text(l10n.settingsMainlandSdkDisclosureTitle),
              subtitle: Text(l10n.settingsMainlandSdkDisclosureSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openRouteRespectingShell(
                context,
                AppRoutes.settingsMainlandSdkDisclosure,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aboutLinkOpenFailed)),
      );
    }
  }
}
