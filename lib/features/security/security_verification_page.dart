import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n_x.dart';
import '../../core/layout/adaptive_layout.dart';
import '../../core/network/browser_connection_policy.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared/widgets/operations/async_state_page_body_widget.dart';
import '../../shared/widgets/section_card.dart';
import '../settings/settings_provider.dart';
import '../shell/controllers/current_server_controller.dart';
import '../shell/widgets/server_aware_page_scaffold.dart';

class SecurityVerificationPage extends StatelessWidget {
  const SecurityVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final server = context.watch<CurrentServerController>().currentServer;
    return ServerAwarePageScaffold(
      title: context.l10n.securityPageTitle,
      body: server == null
          ? const SizedBox.shrink()
          : ChangeNotifierProvider(
              key: ValueKey((server.id, server.revision)),
              create: (_) =>
                  SettingsProvider.forServer(server)..loadSystemSettings(),
              child: Consumer<SettingsProvider>(
                builder: (context, provider, _) {
                  final settings = provider.data.systemSettings;
                  return AsyncStatePageBodyWidget(
                    isLoading: settings == null && provider.loadError == null,
                    errorMessage: provider.loadError,
                    onRetry: provider.loadSystemSettings,
                    child: AdaptiveWidthContainer(
                      maxWidth:
                          AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
                      child: ListView(
                        padding: AppDesignTokens.scrollPagePadding(context),
                        children: [
                          PanelAccountSettingsEntry(
                            serverUrl: server.url,
                            securityEntrance: settings?.securityEntrance,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class PanelAccountSettingsEntry extends StatelessWidget {
  const PanelAccountSettingsEntry({
    super.key,
    required this.serverUrl,
    required this.securityEntrance,
  });

  final String? serverUrl;
  final String? securityEntrance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = serverUrl;
    return SectionEntryList(
      items: [
        SectionEntryItem(
          icon: Icons.manage_accounts_outlined,
          title: l10n.settingsPanelAccountSecurity,
          subtitle: l10n.settingsPanelAccountSecurityDescription,
          trailing: const Icon(Icons.open_in_new_outlined),
          onTap: url == null ? null : () => _openPanel(context, url),
        ),
      ],
    );
  }

  Future<void> _openPanel(BuildContext context, String url) async {
    try {
      final entrance =
          BrowserConnectionPolicy.panelWebEntrance(url, securityEntrance);
      if (await launchUrl(entrance, mode: LaunchMode.externalApplication)) {
        return;
      }
    } on Exception {
      // 平台无法启动浏览器时显示操作反馈。
    } on ArgumentError {
      // 地址验证失败时显示相同反馈。
    }
    if (context.mounted) {
      SnackBarUtils.showError(context, context.l10n.aboutLinkOpenFailed);
    }
  }
}
