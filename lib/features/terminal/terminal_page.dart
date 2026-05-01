import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/terminal_settings_page.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';
import 'package:onepanel_client/features/terminal/providers/terminal_workbench_provider.dart';
import 'package:onepanel_client/features/terminal/services/terminal_appearance.dart';
import 'package:onepanel_client/features/terminal/services/terminal_runtime_session.dart';
import 'package:provider/provider.dart';
import 'package:xterm/ui.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({
    super.key,
    this.provider,
    this.launchIntentOverride,
  });

  final TerminalWorkbenchProvider? provider;
  final TerminalLaunchIntent? launchIntentOverride;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late final TerminalWorkbenchProvider _provider;
  bool _bootstrapped = false;
  bool _didOpenExplicitMobileDetail = false;
  late TerminalLaunchIntent _initialIntent;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? TerminalWorkbenchProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    _initialIntent = widget.launchIntentOverride ??
        TerminalLaunchIntent.fromRouteArgs(
          ModalRoute.of(context)?.settings.arguments,
        );
    _initialize();
  }

  Future<void> _initialize() async {
    await _provider.initialize(_initialIntent);
    if (!mounted ||
        _didOpenExplicitMobileDetail ||
        !_initialIntent.isExplicitSession ||
        _isWideLayout(context)) {
      return;
    }
    final session = _provider.activeSession;
    if (session == null) {
      return;
    }
    _didOpenExplicitMobileDetail = true;
    await _openSessionDetail(session);
  }

  bool _isWideLayout(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return PlatformUtils.isDesktop(context) || width >= 900;
  }

  @override
  void dispose() {
    if (widget.provider == null) {
      _provider.dispose();
    }
    super.dispose();
  }

  Future<void> _openSessionDetail(TerminalRuntimeSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<TerminalWorkbenchProvider>.value(
          value: _provider,
          child: _TerminalSessionDetailPage(
            sessionKey: session.descriptor.sessionKey,
          ),
        ),
      ),
    );
  }

  Future<void> _openHostPicker() async {
    final selected = await showModalBottomSheet<HostTreeChild>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HostPickerSheet(hostTree: _provider.hostTree),
    );
    if (selected == null || !mounted) {
      return;
    }
    final session = await _provider.openSavedHostSession(
      hostId: selected.id,
      hostLabel: selected.label,
    );
    if (session != null && mounted && !_isWideLayout(context)) {
      await _openSessionDetail(session);
    }
  }

  Future<void> _openLocalSession() async {
    final session = await _provider.openLocalSession();
    if (session != null && mounted && !_isWideLayout(context)) {
      await _openSessionDetail(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TerminalWorkbenchProvider>.value(
      value: _provider,
      child: Consumer<TerminalWorkbenchProvider>(
        builder: (context, provider, _) {
          final l10n = context.l10n;
          return Scaffold(
            appBar: AppBar(
              title: Text(_initialIntent.title(context)),
              actions: <Widget>[
                IconButton(
                  onPressed: provider.isLoading ? null : provider.refreshCatalogs,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.commonRefresh,
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TerminalSettingsPage(
                          provider: SettingsProvider(),
                        ),
                      ),
                    );
                    if (context.mounted) {
                      await provider.refreshCatalogs();
                    }
                  },
                  icon: const Icon(Icons.tune_outlined),
                  tooltip: l10n.terminalSettingsTitle,
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isWideLayout(context)
                    ? _TerminalWorkbenchWideLayout(
                        provider: provider,
                        onOpenHostPicker: _openHostPicker,
                        onOpenLocalSession: _openLocalSession,
                      )
                    : _TerminalWorkbenchMobileLayout(
                        provider: provider,
                        onOpenHostPicker: _openHostPicker,
                        onOpenLocalSession: _openLocalSession,
                        onOpenSessionDetail: _openSessionDetail,
                      ),
          );
        },
      ),
    );
  }
}

class _TerminalWorkbenchWideLayout extends StatelessWidget {
  const _TerminalWorkbenchWideLayout({
    required this.provider,
    required this.onOpenHostPicker,
    required this.onOpenLocalSession,
  });

  final TerminalWorkbenchProvider provider;
  final Future<void> Function() onOpenHostPicker;
  final Future<void> Function() onOpenLocalSession;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 320,
          child: _WorkbenchSidebar(
            provider: provider,
            onOpenHostPicker: onOpenHostPicker,
            onOpenLocalSession: onOpenLocalSession,
            onSessionTap: (session) async =>
                provider.selectSession(session.descriptor.sessionKey),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: provider.activeSession == null
              ? const _EmptyTerminalState()
              : _TerminalSessionViewport(
                  session: provider.activeSession!,
                  provider: provider,
                ),
        ),
      ],
    );
  }
}

class _TerminalWorkbenchMobileLayout extends StatelessWidget {
  const _TerminalWorkbenchMobileLayout({
    required this.provider,
    required this.onOpenHostPicker,
    required this.onOpenLocalSession,
    required this.onOpenSessionDetail,
  });

  final TerminalWorkbenchProvider provider;
  final Future<void> Function() onOpenHostPicker;
  final Future<void> Function() onOpenLocalSession;
  final Future<void> Function(TerminalRuntimeSession session) onOpenSessionDetail;

  @override
  Widget build(BuildContext context) {
    return _WorkbenchSidebar(
      provider: provider,
      onOpenHostPicker: onOpenHostPicker,
      onOpenLocalSession: onOpenLocalSession,
      onSessionTap: onOpenSessionDetail,
    );
  }
}

class _WorkbenchSidebar extends StatelessWidget {
  const _WorkbenchSidebar({
    required this.provider,
    required this.onOpenHostPicker,
    required this.onOpenLocalSession,
    required this.onSessionTap,
  });

  final TerminalWorkbenchProvider provider;
  final Future<void> Function() onOpenHostPicker;
  final Future<void> Function() onOpenLocalSession;
  final Future<void> Function(TerminalRuntimeSession session) onSessionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: AppDesignTokens.pagePadding,
      children: <Widget>[
        Text(
          l10n.serverModuleTerminal,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          provider.localConnection.summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    provider.isLaunchingSession ? null : () => onOpenLocalSession(),
                icon: const Icon(Icons.computer_outlined),
                label: Text(l10n.terminalWorkbenchLocalLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    provider.isLaunchingSession ? null : () => onOpenHostPicker(),
                icon: const Icon(Icons.dns_outlined),
                label: Text(l10n.serverPageTitle),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.terminalWorkbenchSessionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (provider.sessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.terminalWorkbenchNoSessions),
            ),
          )
        else
          ...provider.sessions.map((session) {
            final isActive = provider.activeSession?.descriptor.sessionKey ==
                session.descriptor.sessionKey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(session.descriptor.icon),
                  title: Text(session.descriptor.title),
                  subtitle: Text(
                    switch (session.connectionState) {
                      TerminalSessionConnectionState.connected =>
                        session.latencyMs == null
                            ? l10n.terminalWorkbenchStatusConnected
                            : '${l10n.terminalWorkbenchStatusConnected} · ${session.latencyMs}ms',
                      TerminalSessionConnectionState.connecting => l10n.dashboardServerStatusConnecting,
                      TerminalSessionConnectionState.closed => l10n.terminalWorkbenchStatusClosed,
                      TerminalSessionConnectionState.error =>
                        session.errorMessage ?? l10n.commonError,
                      TerminalSessionConnectionState.idle => l10n.terminalWorkbenchStatusIdle,
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    onPressed: () => provider
                        .closeSession(session.descriptor.sessionKey),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                  ),
                  selected: isActive,
                  onTap: () => onSessionTap(session),
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        Text(
          context.l10n.operationsSshSessionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (provider.activeSshSessions.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: Text(context.l10n.sshSessionsEmptyTitle),
              subtitle: Text(context.l10n.sshSessionsEmptyDescription),
            ),
          )
        else
          ...provider.activeSshSessions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: Text(item.username),
                  subtitle: Text('${item.host} · ${item.terminal}'),
                  trailing: IconButton(
                    onPressed: provider.isDisconnectingSshSession
                        ? null
                        : () => provider.disconnectActiveSshSession(item.pid),
                    icon: const Icon(Icons.link_off_outlined),
                    tooltip: context.l10n.commonClose,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _TerminalSessionDetailPage extends StatefulWidget {
  const _TerminalSessionDetailPage({
    required this.sessionKey,
  });

  final String sessionKey;

  @override
  State<_TerminalSessionDetailPage> createState() =>
      _TerminalSessionDetailPageState();
}

class _TerminalSessionDetailPageState extends State<_TerminalSessionDetailPage> {
  late String _currentSessionKey;

  @override
  void initState() {
    super.initState();
    _currentSessionKey = widget.sessionKey;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalWorkbenchProvider>(
      builder: (context, provider, _) {
        final session =
            provider.sessionByKey(_currentSessionKey) ?? provider.activeSession;
        if (session == null) {
          return Scaffold(
            body: Center(
              child: Text(context.l10n.terminalWorkbenchSessionClosed),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(session.descriptor.title),
            actions: <Widget>[
              IconButton(
                onPressed: () => _pasteFromClipboard(session),
                icon: const Icon(Icons.content_paste_outlined),
                tooltip: context.l10n.terminalWorkbenchPaste,
              ),
              IconButton(
                onPressed: () => _copySelection(session),
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: context.l10n.commonCopy,
              ),
              IconButton(
                onPressed: () => _showQuickCommands(context, provider, session),
                icon: const Icon(Icons.playlist_play_outlined),
                tooltip: context.l10n.terminalWorkbenchQuickCommand,
              ),
              IconButton(
                onPressed: () =>
                    provider.reconnectSession(session.descriptor.sessionKey),
                icon: const Icon(Icons.refresh),
                tooltip: context.l10n.commonRefresh,
              ),
            ],
          ),
          body: _TerminalSessionViewport(
            session: session,
            provider: provider,
            onSelectSession: provider.sessions.length <= 1
                ? null
                : (nextKey) {
                    setState(() {
                      _currentSessionKey = nextKey;
                    });
                    provider.selectSession(nextKey);
                  },
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: session.requestFocus,
                      icon: const Icon(Icons.keyboard_outlined),
                      label: Text(context.l10n.terminalWorkbenchKeyboard),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showQuickCommands(context, provider, session),
                      icon: const Icon(Icons.playlist_play_outlined),
                      label: Text(context.l10n.terminalWorkbenchCommand),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pasteFromClipboard(TerminalRuntimeSession session) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    session.terminal.paste(text);
    session.requestFocus();
  }

  Future<void> _copySelection(TerminalRuntimeSession session) async {
    final selection = session.controller.selection;
    if (selection == null) {
      return;
    }
    final text = session.terminal.buffer.getText(selection);
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    session.clearSelection();
  }

  Future<void> _showQuickCommands(
    BuildContext context,
    TerminalWorkbenchProvider provider,
    TerminalRuntimeSession session,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _QuickCommandSheet(
        commandTree: provider.commandTree,
      ),
    );
    if (selected == null || selected.isEmpty) {
      return;
    }
    await provider.sendQuickCommand(session, selected);
    session.requestFocus();
  }
}

class _TerminalSessionViewport extends StatelessWidget {
  const _TerminalSessionViewport({
    required this.session,
    required this.provider,
    this.onSelectSession,
  });

  final TerminalRuntimeSession session;
  final TerminalWorkbenchProvider provider;
  final ValueChanged<String>? onSelectSession;

  @override
  Widget build(BuildContext context) {
    final terminalSettings = provider.terminalSettings;
    final theme = TerminalAppearance.buildTheme(terminalSettings);
    final style = TerminalAppearance.buildTextStyle(terminalSettings);

    return Padding(
      padding: AppDesignTokens.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (provider.sessions.length > 1) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = provider.sessions[index];
                  final selected = item.descriptor.sessionKey ==
                      session.descriptor.sessionKey;
                  return ChoiceChip(
                    label: Text(item.descriptor.title),
                    selected: selected,
                    onSelected: (_) =>
                        onSelectSession?.call(item.descriptor.sessionKey),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: <Widget>[
              Icon(
                switch (session.connectionState) {
                  TerminalSessionConnectionState.connected =>
                    Icons.cloud_done_outlined,
                  TerminalSessionConnectionState.connecting =>
                    Icons.cloud_sync_outlined,
                  TerminalSessionConnectionState.closed =>
                    Icons.cloud_off_outlined,
                  TerminalSessionConnectionState.error =>
                    Icons.error_outline,
                  TerminalSessionConnectionState.idle =>
                    Icons.terminal_outlined,
                },
                size: 18,
                color: switch (session.connectionState) {
                  TerminalSessionConnectionState.connected => Colors.green,
                  TerminalSessionConnectionState.connecting => Colors.orange,
                  TerminalSessionConnectionState.closed => Colors.grey,
                  TerminalSessionConnectionState.error => Colors.redAccent,
                  TerminalSessionConnectionState.idle => null,
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.errorMessage ?? _statusText(context, session),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(
                  AppDesignTokens.radiusLg,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDesignTokens.radiusLg,
                ),
                child: TerminalView(
                  session.terminal,
                  controller: session.controller,
                  focusNode: session.focusNode,
                  autofocus: true,
                  deleteDetection: true,
                  keyboardType: TextInputType.visiblePassword,
                  theme: theme,
                  textStyle: style,
                  cursorType: _cursorTypeFromSettings(
                    provider.terminalSettings?.cursorStyle,
                  ),
                  onTapUp: (_, __) => session.requestFocus(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TerminalCursorType _cursorTypeFromSettings(String? value) {
    switch (value?.toLowerCase()) {
      case 'underline':
        return TerminalCursorType.underline;
      case 'bar':
        return TerminalCursorType.verticalBar;
      case 'block':
      default:
        return TerminalCursorType.block;
    }
  }

  String _statusText(BuildContext context, TerminalRuntimeSession session) {
    final l10n = context.l10n;
    final base = switch (session.connectionState) {
      TerminalSessionConnectionState.connected =>
        l10n.terminalWorkbenchStatusConnected,
      TerminalSessionConnectionState.connecting =>
        l10n.dashboardServerStatusConnecting,
      TerminalSessionConnectionState.closed => l10n.terminalWorkbenchStatusClosed,
      TerminalSessionConnectionState.error => session.errorMessage ?? l10n.commonError,
      TerminalSessionConnectionState.idle => l10n.terminalWorkbenchStatusIdle,
    };
    if (session.connectionState != TerminalSessionConnectionState.connected ||
        session.latencyMs == null) {
      return base;
    }
    return '$base · ${session.latencyMs}ms';
  }
}

class _EmptyTerminalState extends StatelessWidget {
  const _EmptyTerminalState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(context.l10n.terminalWorkbenchOpenHint),
    );
  }
}

class _HostPickerSheet extends StatefulWidget {
  const _HostPickerSheet({
    required this.hostTree,
  });

  final List<HostTreeNode> hostTree;

  @override
  State<_HostPickerSheet> createState() => _HostPickerSheetState();
}

class _HostPickerSheetState extends State<_HostPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.hostTree
        .map((group) => HostTreeNode(
              id: group.id,
              label: group.label,
              children: group.children
                  .where(
                    (item) => _query.isEmpty ||
                        item.label.toLowerCase().contains(_query.toLowerCase()),
                  )
                  .toList(growable: false),
            ))
        .where((group) => group.children.isNotEmpty)
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.terminalWorkbenchSearchHost,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: groups.map((group) {
                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(group.label),
                    children: group.children.map((child) {
                      return ListTile(
                        title: Text(child.label),
                        leading: const Icon(Icons.dns_outlined),
                        onTap: () => Navigator.of(context).pop(child),
                      );
                    }).toList(growable: false),
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCommandSheet extends StatefulWidget {
  const _QuickCommandSheet({
    required this.commandTree,
  });

  final List<CommandTree> commandTree;

  @override
  State<_QuickCommandSheet> createState() => _QuickCommandSheetState();
}

class _QuickCommandSheetState extends State<_QuickCommandSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commands = _flatten(widget.commandTree)
        .where((entry) {
          if (_query.isEmpty) {
            return true;
          }
          final q = _query.toLowerCase();
          return entry.label.toLowerCase().contains(q) ||
              entry.value.toLowerCase().contains(q);
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.terminalWorkbenchQuickCommand,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: commands.length,
                itemBuilder: (context, index) {
                  final item = commands[index];
                  return ListTile(
                    title: Text(item.label),
                    subtitle: Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(item.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_QuickCommandEntry> _flatten(
    List<CommandTree> nodes, {
    String parent = '',
  }) {
    final results = <_QuickCommandEntry>[];
    for (final node in nodes) {
      final label = node.label?.trim();
      final nextLabel = parent.isEmpty
          ? (label ?? '')
          : (label == null || label.isEmpty ? parent : '$parent / $label');
      final children = node.children ?? const <CommandTree>[];
      if (children.isEmpty && node.value?.trim().isNotEmpty == true) {
        results.add(
          _QuickCommandEntry(
            label: nextLabel.isEmpty ? (node.value ?? '') : nextLabel,
            value: node.value!.trim(),
          ),
        );
        continue;
      }
      results.addAll(_flatten(children, parent: nextLabel));
    }
    return results;
  }
}

class _QuickCommandEntry {
  const _QuickCommandEntry({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
