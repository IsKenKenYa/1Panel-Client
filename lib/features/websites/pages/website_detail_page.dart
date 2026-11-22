import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

import '../providers/website_detail_provider.dart';
import '../widgets/website_common_widgets.dart';
import '../widgets/website_overview_card_widget.dart';
import '../widgets/website_workbench_card_widget.dart';

class WebsiteDetailPage extends StatelessWidget {
  const WebsiteDetailPage({
    super.key,
    required this.websiteId,
  });

  final int websiteId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebsiteDetailProvider(websiteId: websiteId)..loadDetail(),
      child: const _WebsiteDetailBody(),
    );
  }
}

class _WebsiteDetailBody extends StatelessWidget {
  const _WebsiteDetailBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteDetailProvider>(
      builder: (context, provider, _) {
        final website = provider.website;
        final title = website?.displayDomain ??
            '${l10n.websitesDetailTitle} #${provider.websiteId}';

        if (provider.isLoading && website == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && website == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(title)),
            body: WebsiteErrorSection(
              message: provider.error!,
              onRetry: provider.loadDetail,
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: provider.loadDetail,
                tooltip: l10n.commonRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => openRouteRespectingShell(
                  context,
                  AppRoutes.securityGatewayCenter,
                  arguments: {
                    'initialSection': SecurityGatewaySection.openresty.name,
                    'websiteId': provider.websiteId,
                    'displayName': website?.displayDomain,
                  },
                ),
                tooltip: l10n.openrestyPageTitle,
              ),
            ],
          ),
          body: ListView(
            padding: AppDesignTokens.cardPadding,
            children: [
              WebsiteOverviewCard(website: website),
              const SizedBox(height: 12),
              WebsiteActionCard(
                website: website,
                onOperate: provider.operate,
                onEdit: () => _openEdit(context, provider.websiteId),
                onSetDefault: provider.setDefaultServer,
                onDelete: () => _confirmDelete(context, provider),
              ),
              const SizedBox(height: 12),
              WebsiteWorkbenchCard(
                websiteId: provider.websiteId,
                website: website,
                onOpenConfig: () => openRouteRespectingShell(
                    context,
                    AppRoutes.websiteConfigCenter,
                    arguments: {
                      'websiteId': provider.websiteId,
                      'displayName': website?.displayDomain,
                    },
                  ),
                onOpenDomains: () => openRouteRespectingShell(
                    context,
                    AppRoutes.websiteDomains,
                    arguments: {
                      'websiteId': provider.websiteId,
                      'primaryDomain': website?.primaryDomain,
                    },
                  ),
                onOpenSsl: () => openRouteRespectingShell(
                  context,
                  AppRoutes.securityGatewayCenter,
                  arguments: {
                    'initialSection':
                        SecurityGatewaySection.websiteCertificates.name,
                    'websiteId': provider.websiteId,
                    'displayName': website?.displayDomain,
                  },
                ),
                onOpenRouting: () => openRouteRespectingShell(
                    context,
                    AppRoutes.websiteRoutingRules,
                    arguments: {
                      'websiteId': provider.websiteId,
                      'displayName': website?.displayDomain,
                    },
                  ),
                onOpenOpenResty: () => openRouteRespectingShell(
                  context,
                  AppRoutes.securityGatewayCenter,
                  arguments: {
                    'initialSection': SecurityGatewaySection.openresty.name,
                    'websiteId': provider.websiteId,
                    'displayName': website?.displayDomain,
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WebsiteDetailProvider provider,
  ) async {
    final website = provider.website;
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.websitesDeleteTitle,
      message: l10n.websitesDeleteMessage(
        website?.displayDomain ?? l10n.websitesUnknownDomain,
      ),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteWebsite();
      } catch (error) {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            ErrorMessageUtils.localizeForContext(
              ErrorMessageUtils.normalize(error),
              context,
            ),
          );
        }
        return;
      }
      // pop(true) 通知列表页刷新：删除已成功，列表统计不能停留旧值。
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _openEdit(BuildContext context, int websiteId) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.websiteEdit,
      arguments: {'websiteId': websiteId},
    );
    if (result == true && context.mounted) {
      await context.read<WebsiteDetailProvider>().loadDetail();
    }
  }
}
