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
}) {
  switch (module) {
    case ClientModule.servers:
      return const ServerListPage();
    case ClientModule.files:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.navFiles);
      }
      return KeyedSubtree(
        key: ValueKey('files:$serverId'),
        child: const FilesPage(),
      );
    case ClientModule.containers:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.containerManagement);
      }
      return KeyedSubtree(
        key: ValueKey('containers:$serverId'),
        child: const ContainersPage(),
      );
    case ClientModule.apps:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.appsPageTitle);
      }
      return KeyedSubtree(
        key: ValueKey('apps:$serverId'),
        child: const AppsPage(),
      );
    case ClientModule.websites:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.websitesPageTitle);
      }
      return KeyedSubtree(
        key: ValueKey('websites:$serverId'),
        child: const WebsitesPage(),
      );
    case ClientModule.ai:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.serverModuleAi);
      }
      return KeyedSubtree(
        key: ValueKey('ai:$serverId'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AIProvider()),
            ChangeNotifierProvider(create: (_) => McpServerProvider()),
          ],
          child: const AIPage(),
        ),
      );
    case ClientModule.verification:
      if (serverId == null) {
        return NoServerSelectedState(moduleName: context.l10n.serverActionSecurity);
      }
      return KeyedSubtree(
        key: ValueKey('verification:$serverId'),
        child: const SecurityVerificationPage(),
      );
    case ClientModule.settings:
      return const SettingsPage();
  }
}

