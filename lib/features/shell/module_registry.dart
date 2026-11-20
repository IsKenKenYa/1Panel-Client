import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_page.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/containers/containers_page.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_page.dart';
import 'package:onepanel_client/features/websites/websites_page.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';

/// Describes how a [ClientModule] is built and opened.
///
/// Each module self-registers its page builder here so that adding a new
/// module only requires touching this registry (plus the [ClientModule]
/// enum) instead of synchronising switches across
/// `module_page_factory.dart` and `app_shell_page.dart`.
class ModuleRegistration {
  const ModuleRegistration({
    required this.module,
    required this.builder,
    this.standaloneBuilder,
  });

  final ClientModule module;

  /// Builds the module page for embedding inside a shell container.
  /// The builder receives the [BuildContext] so it can resolve l10n for
  /// the "no server selected" placeholder.
  final WidgetBuilder builder;

  /// Builds the module page for a full-screen standalone push (outside
  /// the shell). When `null`, the module is not openable standalone and
  /// the shell handles it internally.
  final WidgetBuilder? standaloneBuilder;
}

/// Central registry of module page builders.
///
/// Replaces the duplicated `switch (module)` statements that previously
/// lived in `module_page_factory.dart` and `app_shell_page.dart`.
class ModuleRegistry {
  const ModuleRegistry._();

  static final Map<ClientModule, ModuleRegistration> _entries = {
    for (final entry in _all) entry.module: entry,
  };

  static ModuleRegistration? registrationFor(ClientModule module) =>
      _entries[module];

  /// Builds the AI module page with its required providers.
  ///
  /// This is the **single registration point** for AIProvider,
  /// AgentsProvider, and McpServerProvider. Both the shell-embedded path
  /// ([buildShellPage]) and the routed path ([app_router.dart] AI route)
  /// must delegate here to avoid creating independent provider instances
  /// that lose state on navigation (architecture review candidate ⑧).
  static Widget buildAiModule(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AIProvider()),
          ChangeNotifierProvider(create: (_) => AgentsProvider()),
          ChangeNotifierProvider(create: (_) => McpServerProvider()),
          ChangeNotifierProvider(create: (_) => ModelDownloaderProvider()),
        ],
        child: const AIPage(),
      );

  /// Builds the shell-embedded page for [module], applying the server-id
  /// keying guard so Flutter rebuilds the subtree when switching servers.
  static Widget buildShellPage(
    BuildContext context,
    ClientModule module, {
    required String? serverId,
    bool useStableModuleKey = false,
  }) {
    final reg = _entries[module];
    if (reg == null) {
      return const SizedBox.shrink();
    }
    // Modules that require a server show a placeholder instead of the
    // real page when no server is active.
    if (module.requiresServer && serverId == null) {
      return NoServerSelectedState(moduleName: module.label(context.l10n));
    }
    final page = reg.builder(context);
    if (useStableModuleKey) return page;
    return KeyedSubtree(
      key: ValueKey('${module.storageId}:$serverId'),
      child: page,
    );
  }

  /// Returns the standalone page for [module], or `null` when the module
  /// does not support standalone push.
  static Widget? buildStandalonePage(ClientModule module, BuildContext context) {
    return _entries[module]?.standaloneBuilder?.call(context);
  }

  static const List<ModuleRegistration> _all = [
    ModuleRegistration(
      module: ClientModule.servers,
      builder: _serversBuilder,
    ),
    ModuleRegistration(
      module: ClientModule.files,
      builder: _filesBuilder,
    ),
    ModuleRegistration(
      module: ClientModule.containers,
      builder: _containersBuilder,
    ),
    ModuleRegistration(
      module: ClientModule.apps,
      builder: _appsBuilder,
      standaloneBuilder: _appsStandalone,
    ),
    ModuleRegistration(
      module: ClientModule.websites,
      builder: _websitesBuilder,
      standaloneBuilder: _websitesStandalone,
    ),
    ModuleRegistration(
      module: ClientModule.ai,
      builder: _aiBuilder,
      standaloneBuilder: _aiStandalone,
    ),
    ModuleRegistration(
      module: ClientModule.vm,
      builder: _vmBuilder,
      standaloneBuilder: _vmStandalone,
    ),
    ModuleRegistration(
      module: ClientModule.verification,
      builder: _verificationBuilder,
      standaloneBuilder: _verificationStandalone,
    ),
    ModuleRegistration(
      module: ClientModule.settings,
      builder: _settingsBuilder,
    ),
  ];

  // --- Builders ---

  static Widget _serversBuilder(BuildContext _) => const ServerListPage();
  static Widget _filesBuilder(BuildContext _) => const FilesPage();
  static Widget _containersBuilder(BuildContext _) => const ContainersPage();
  static Widget _appsBuilder(BuildContext _) => const AppsPage();
  static Widget _websitesBuilder(BuildContext _) => const WebsitesPage();
  static Widget _verificationBuilder(BuildContext _) =>
      const SecurityVerificationPage();
  static Widget _settingsBuilder(BuildContext _) => const SettingsPage();

  /// AI module delegates to [buildAiModule] (single registration point).
  static Widget _aiBuilder(BuildContext ctx) => buildAiModule(ctx);

  /// 虚拟机模块自带 Provider，壳内嵌与独立推送共用同一构造。
  static Widget vmBuilder(BuildContext context) => ChangeNotifierProvider(
        create: (_) => VmProvider(),
        child: const VmPage(),
      );

  static Widget _vmBuilder(BuildContext ctx) => vmBuilder(ctx);

  // Standalone builders reuse the same widget construction as the shell
  // builders since the page content is identical; only the navigation
  // strategy (push vs in-shell swap) differs.
  static Widget _appsStandalone(BuildContext _) => const AppsPage();
  static Widget _websitesStandalone(BuildContext _) => const WebsitesPage();
  static Widget _verificationStandalone(BuildContext _) =>
      const SecurityVerificationPage();
  // _aiStandalone delegates to buildAiModule (single registration point).
  static Widget _aiStandalone(BuildContext ctx) => buildAiModule(ctx);
  static Widget _vmStandalone(BuildContext ctx) => vmBuilder(ctx);
}
