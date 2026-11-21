import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';

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

    return SettingsScaffold(
      title: l10n.settingsLegalCenterTitle,
      body: ListView(
        padding: AppDesignTokens.scrollPagePadding(context),
        children: [
          SectionEntryList(
            title: l10n.settingsLegalDocumentsTitle,
            items: [
              SectionEntryItem(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsLegalPrivacyPolicy,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternal(context, privacyUrl),
              ),
              SectionEntryItem(
                icon: Icons.gavel_outlined,
                title: l10n.settingsLegalTermsOfService,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternal(context, _termsUrl),
              ),
              SectionEntryItem(
                icon: Icons.copyright_outlined,
                title: l10n.settingsLegalThirdPartyNotices,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternal(context, _thirdPartyNoticesUrl),
              ),
              SectionEntryItem(
                icon: Icons.description_outlined,
                title: l10n.settingsLegalOpenSourceLicense,
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternal(context, _openSourceLicenseUrl),
              ),
              SectionEntryItem(
                icon: Icons.library_books_outlined,
                title: l10n.settingsLegalFlutterPackages,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          SectionEntryList(
            items: [
              SectionEntryItem(
                icon: Icons.developer_board_outlined,
                title: l10n.settingsMainlandSdkDisclosureTitle,
                subtitle: l10n.settingsMainlandSdkDisclosureSubtitle,
                onTap: () => openRouteRespectingShell(
                  context,
                  AppRoutes.settingsMainlandSdkDisclosure,
                ),
              ),
            ],
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
      SnackBarUtils.showError(context, context.l10n.aboutLinkOpenFailed);
    }
  }
}
