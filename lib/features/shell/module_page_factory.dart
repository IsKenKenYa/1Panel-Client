import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_page.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/containers/containers_page.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/websites/websites_page.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:provider/provider.dart';

/// Shared factory for building module pages inside shell containers (mobile,
/// desktop/common, and native-shell content panes).
///
/// This keeps UI composition in one place to avoid duplicated switch statements,
/// while business logic remains in providers/services.
Widget buildShellModulePage(
  BuildContext context, {
  required ClientModule module,
  required String? serverId,
  bool useStableModuleKey = false,
}) {
  switch (module) {
    case ClientModule.servers:
      return const ServerListPage();
    case ClientModule.files:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.navFiles);
      }
      final filesPage = const FilesPage();
      return useStableModuleKey
          ? filesPage
          : KeyedSubtree(
              key: ValueKey('files:$serverId'),
              child: filesPage,
            );
    case ClientModule.containers:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.containerManagement);
      }
      final containersPage = const ContainersPage();
      return useStableModuleKey
          ? containersPage
          : KeyedSubtree(
              key: ValueKey('containers:$serverId'),
              child: containersPage,
            );
    case ClientModule.apps:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.appsPageTitle);
      }
      final appsPage = const AppsPage();
      return useStableModuleKey
          ? appsPage
          : KeyedSubtree(
              key: ValueKey('apps:$serverId'),
              child: appsPage,
            );
    case ClientModule.websites:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.websitesPageTitle);
      }
      final websitesPage = const WebsitesPage();
      return useStableModuleKey
          ? websitesPage
          : KeyedSubtree(
              key: ValueKey('websites:$serverId'),
              child: websitesPage,
            );
    case ClientModule.ai:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.serverModuleAi);
      }
      final aiPage = MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AIProvider()),
          ChangeNotifierProvider(create: (_) => McpServerProvider()),
        ],
        child: const AIPage(),
      );
      return useStableModuleKey
          ? aiPage
          : KeyedSubtree(
              key: ValueKey('ai:$serverId'),
              child: aiPage,
            );
    case ClientModule.verification:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.serverActionSecurity);
      }
      final verificationPage = const SecurityVerificationPage();
      return useStableModuleKey
          ? verificationPage
          : KeyedSubtree(
              key: ValueKey('verification:$serverId'),
              child: verificationPage,
            );
    case ClientModule.settings:
      return const SettingsPage();
  }
}
