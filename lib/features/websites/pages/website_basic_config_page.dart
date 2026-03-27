import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_config_center_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_section_card.dart';

class WebsiteBasicConfigPage extends StatelessWidget {
  const WebsiteBasicConfigPage({
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
    if (provider != null) {
      return ChangeNotifierProvider<WebsiteConfigCenterProvider>.value(
        value: provider!,
        child:
            _WebsiteBasicConfigBody(displayName: displayName, websiteId: websiteId),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => WebsiteConfigCenterProvider(websiteId: websiteId)..load(),
      child: _WebsiteBasicConfigBody(displayName: displayName, websiteId: websiteId),
    );
  }
}

class _WebsiteBasicConfigBody extends StatelessWidget {
  const _WebsiteBasicConfigBody({
    required this.websiteId,
    this.displayName,
  });

  final int websiteId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = displayName == null
        ? l10n.websitesBasicConfigTitle
        : '${l10n.websitesBasicConfigTitle} · $displayName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<WebsiteConfigCenterProvider>(
        builder: (context, provider, _) {
          final website = provider.website;
          return WebsiteAsyncStateView(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: provider.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                WebsiteSectionCard(
                  title: l10n.websitesSitePathLabel,
                  subtitle: website?.sitePath ?? website?.siteDir ?? '-',
                  icon: Icons.folder_outlined,
                  trailing: null,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesRuntimeLabel,
                  subtitle:
                      website?.runtimeName ?? website?.runtimeTypeName ?? '-',
                  icon: Icons.data_object_outlined,
                  trailing: null,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesBasicConfigDatabaseTitle,
                  subtitle: website?.dbType ?? '-',
                  icon: Icons.storage_outlined,
                  trailing: null,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesHttpsConfigTitle,
                  subtitle: provider.httpsSummary?.toString() ?? '-',
                  icon: Icons.lock_outline,
                  trailing: null,
                ),
                WebsiteSectionCard(
                  title: l10n.websitesRemarkLabel,
                  subtitle: website?.remark ?? '-',
                  icon: Icons.edit_note_outlined,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.websiteEdit,
                    arguments: {'websiteId': websiteId},
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
