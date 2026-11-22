import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class FirewallV2Page extends StatelessWidget {
  const FirewallV2Page({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.firewallV2Title,
      body: SafeArea(
        child: ListView(
          padding: AppDesignTokens.cardPadding,
          children: [
            SectionEntryList(
              title: l10n.firewallV2SectionTitle,
              description: l10n.firewallV2SectionDesc,
              items: [
                SectionEntryItem(
                  icon: Icons.shield_outlined,
                  title: l10n.firewallV2SystemRules,
                  subtitle: l10n.firewallV2SystemRulesDesc,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.firewallV2Rules,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.call_split_outlined,
                  title: l10n.firewallV2Forward,
                  subtitle: l10n.firewallV2ForwardDesc,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.firewallV2Forward,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.dns_outlined,
                  title: l10n.firewallV2Docker,
                  subtitle: l10n.firewallV2DockerDesc,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.firewallV2Docker,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.settings_outlined,
                  title: l10n.firewallV2Settings,
                  subtitle: l10n.firewallV2SettingsDesc,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.firewallV2Settings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
