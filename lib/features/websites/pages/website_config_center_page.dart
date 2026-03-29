import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_config_center_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_section_card.dart';
import '../website_config_page.dart';
import 'website_basic_config_page.dart';
import 'website_routing_rules_page.dart';
import 'website_security_access_page.dart';

class WebsiteConfigCenterPage extends StatelessWidget {
  const WebsiteConfigCenterPage({
    super.key,
    required this.websiteId,
    this.displayName,
    this.provider,
  });

  final int websiteId;
  final String? displayName;
  final WebsiteConfigCenterProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          provider ?? WebsiteConfigCenterProvider(websiteId: websiteId)
            ..load(),
      child: _WebsiteConfigCenterBody(
        websiteId: websiteId,
        displayName: displayName,
      ),
    );
  }
}

class _WebsiteConfigCenterBody extends StatelessWidget {
  const _WebsiteConfigCenterBody({
    required this.websiteId,
    this.displayName,
  });

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = displayName == null
        ? l10n.websitesConfigPageTitle
        : '${l10n.websitesConfigPageTitle} · $displayName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<WebsiteConfigCenterProvider>(
        builder: (context, provider, _) {
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                WebsiteSectionCard(
                  title: l10n.websitesBasicConfigTitle,
                  subtitle: provider.website?.sitePath ??
                      l10n.websitesConfigPageSubtitle,
                  icon: Icons.dashboard_customize_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteBasicConfigPage(
                        websiteId: websiteId,
                        displayName: displayName,
                        provider: provider,
                      ),
                    ),
                  ),
                ),
                WebsiteSectionCard(
                  title:
                      '${l10n.websitesTabProxy} / ${l10n.websitesTabRewrite}',
                  subtitle: l10n.websitesConfigScopeTitle,
                  icon: Icons.alt_route,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteRoutingRulesPage(
                        websiteId: websiteId,
                        displayName: displayName,
                      ),
                    ),
                  ),
                ),
                WebsiteSectionCard(
                  title: l10n.securitySettingsAccessControl,
                  subtitle: l10n.websitesConfigPageSubtitle,
                  icon: Icons.shield_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteSecurityAccessPage(
                        websiteId: websiteId,
                        displayName: displayName,
                      ),
                    ),
                  ),
                ),
                WebsiteSectionCard(
                  title: l10n.websitesPhpVersionTitle,
                  subtitle: provider.website?.runtimeName ??
                      l10n.websitesConfigPageSubtitle,
                  icon: Icons.code_off,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteConfigPage(
                        websiteId: websiteId,
                        displayName: displayName,
                      ),
                    ),
                  ),
                ),
                WebsiteSectionCard(
                  title: l10n.websitesConfigEditorTitle,
                  subtitle: provider.configFile?.path ??
                      l10n.websitesConfigPageSubtitle,
                  icon: Icons.code,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WebsiteConfigPage(
                        websiteId: websiteId,
                        displayName: displayName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
