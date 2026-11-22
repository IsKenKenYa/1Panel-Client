import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class ToolboxCenterPage extends StatelessWidget {
  const ToolboxCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.toolboxCenterTitle,
      body: ListView(
        padding: AppDesignTokens.cardPadding,
        children: [
          Card(
            child: Padding(
              padding: AppDesignTokens.cardPadding,
              child: Text(
                l10n.toolboxCenterIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionEntryList(
            title: l10n.toolboxCenterTitle,
            items: [
              SectionEntryItem(
                title: l10n.toolboxClamTitle,
                subtitle: l10n.toolboxClamCardSubtitle,
                icon: Icons.security_outlined,
                onTap: () =>
                    openRouteRespectingShell(context, AppRoutes.toolboxClam),
              ),
              SectionEntryItem(
                title: l10n.toolboxFail2banTitle,
                subtitle: l10n.toolboxFail2banCardSubtitle,
                icon: Icons.gpp_bad_outlined,
                onTap: () => openRouteRespectingShell(
                    context, AppRoutes.toolboxFail2ban),
              ),
              SectionEntryItem(
                title: l10n.toolboxFtpTitle,
                subtitle: l10n.toolboxFtpCardSubtitle,
                icon: Icons.folder_shared_outlined,
                onTap: () =>
                    openRouteRespectingShell(context, AppRoutes.toolboxFtp),
              ),
              SectionEntryItem(
                title: l10n.toolboxDeviceTitle,
                subtitle: l10n.toolboxDeviceCardSubtitle,
                icon: Icons.developer_board_outlined,
                onTap: () => openRouteRespectingShell(
                    context, AppRoutes.toolboxDevice),
              ),
              SectionEntryItem(
                title: l10n.toolboxDiskTitle,
                subtitle: l10n.toolboxDiskCardSubtitle,
                icon: Icons.storage_outlined,
                onTap: () =>
                    openRouteRespectingShell(context, AppRoutes.toolboxDisk),
              ),
              SectionEntryItem(
                title: l10n.toolboxHostToolTitle,
                subtitle: l10n.toolboxHostToolCardSubtitle,
                icon: Icons.settings_applications_outlined,
                onTap: () => openRouteRespectingShell(
                    context, AppRoutes.toolboxHostTool),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
