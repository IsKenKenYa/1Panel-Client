import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';

import 'panels/panel_presentation.dart';
import 'server_list_interactions.dart';
import 'server_models.dart';
import 'server_provider.dart';
import 'widgets/server_actions_menu.dart';
import 'widgets/server_detail_header_card.dart';

class ServerDetailPage extends StatefulWidget {
  const ServerDetailPage({super.key, required this.server});

  final ApiConfig server;

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage> {
  late bool _followCurrent =
      context.read<CurrentServerController>().currentServerId ==
      widget.server.id;

  @override
  void didUpdateWidget(ServerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _followCurrent =
          context.read<CurrentServerController>().currentServerId ==
          widget.server.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.select(
      (CurrentServerController c) => c.currentServerId,
    );
    final config = _followCurrent
        ? context.select((CurrentServerController c) => c.currentServer)
        : context.select(
            (ServerProvider p) =>
                p.cardFor(widget.server.id)?.config ??
                (p.hasDirectory ? null : widget.server),
          );
    final panel = PanelPresentations.entries[config?.panelType];
    final title = context.l10n.serverDetailTitle;
    return AdaptiveLayoutViewport(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            ServerSwitcherAction(
              displayedServer: config,
              onChanged: () async {
                if (!_followCurrent) setState(() => _followCurrent = true);
              },
            ),
            if (config != null)
              ServerActionsMenu(
                onEdit: panel == null
                    ? null
                    : () => openServerForm(context, serverId: config.id),
                onDelete: () async {
                  final deleted = await confirmAndDeleteServer(context, config);
                  if (deleted &&
                      context.mounted &&
                      ModalRoute.isCurrentOf(context) != false) {
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
        body: config == null
            ? NoServerSelectedState(moduleName: title)
            : _ServerDetailBody(
                key: ValueKey((config.id, config.revision)),
                config: config,
                isCurrent: config.id == current,
                panel: panel,
              ),
      ),
    );
  }
}

class _ServerDetailBody extends StatefulWidget {
  const _ServerDetailBody({
    super.key,
    required this.config,
    required this.isCurrent,
    required this.panel,
  });

  final ApiConfig config;
  final bool isCurrent;
  final PanelPresentation? panel;

  @override
  State<_ServerDetailBody> createState() => _ServerDetailBodyState();
}

class _ServerDetailBodyState extends State<_ServerDetailBody> {
  bool _visible = false;
  final _refreshing = ValueNotifier(false);
  Future<Map<String, PanelAccess>>? _access;

  Future<Map<String, PanelAccess>>? _readCapabilities() =>
      widget.panel?.needsCapabilities == true
      ? context.read<ServerProvider>().capabilitiesFor(widget.config.id)
      : null;

  bool get _canShowFeedback {
    if (!_visible || ModalRoute.isCurrentOf(context) == false) {
      return false;
    }
    if (widget.isCurrent &&
        context.read<CurrentServerController>().currentServerId !=
            widget.config.id) {
      return false;
    }
    final card = context.read<ServerProvider>().cardFor(widget.config.id);
    return card != null && card.config.revision == widget.config.revision;
  }

  @override
  void dispose() {
    _refreshing.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing.value) return;
    final provider = context.read<ServerProvider>();
    final target = widget.config;
    _refreshing.value = true;
    try {
      final access = _readCapabilities();
      if (access != null) setState(() => _access = access);
      await Future.wait([
        provider.loadMetricsFor(target.id),
        if (access != null) access.then<void>((_) {}),
      ]);
      if (!mounted || !_canShowFeedback) return;
      final card = provider.cardFor(target.id);
      if (card?.metrics.isReachable == false) {
        SnackBarUtils.showError(context, context.l10n.serverUnreachable);
      } else {
        SnackBarUtils.showSuccess(context, context.l10n.commonRefreshSuccess);
      }
    } catch (error) {
      if (mounted && _canShowFeedback) {
        SnackBarUtils.showError(
          context,
          ErrorMessageUtils.userFacingMessage(error),
        );
      }
    } finally {
      if (mounted) _refreshing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final provider = context.select((ServerProvider p) => p);
    final header = Selector<ServerProvider, ServerCardViewModel?>(
      selector: (_, state) => state.cardFor(config.id),
      builder: (context, card, _) => ValueListenableBuilder<bool>(
        valueListenable: _refreshing,
        builder: (context, busy, _) => ServerDetailHeaderCard(
          server: card != null && card.config.revision == config.revision
              ? card
              : ServerCardViewModel(
                  config: config,
                  isCurrent: widget.isCurrent,
                  metrics: const ServerMetricsSnapshot(),
                ),
          onRefresh: busy || widget.panel == null ? null : _refresh,
        ),
      ),
    );
    final modules = _buildModules(context);
    final spec = AdaptiveLayoutSpec.of(context);
    return PageVisibilityListener(
      key: ObjectKey(provider),
      onChanged: (visible) {
        _visible = visible;
        if (widget.panel != null) {
          provider.setPageVisible(this, visible, serverId: config.id);
        }
        if (visible &&
            widget.panel?.needsCapabilities == true &&
            _access == null) {
          setState(() => _access = _readCapabilities());
        }
      },
      child: SingleChildScrollView(
        padding: spec.pagePadding.copyWith(
          bottom:
              spec.pagePadding.bottom + MediaQuery.paddingOf(context).bottom,
        ),
        child: AdaptiveWidthContainer(
          maxWidth: spec.contentMaxWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppDesignTokens.spacingLg;
              if (constraints.maxWidth >= 840) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: header),
                    const SizedBox(width: gap),
                    Expanded(flex: 3, child: modules),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: gap),
                  modules,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModules(BuildContext context) {
    final panel = widget.panel;
    if (panel == null) {
      return ModuleErrorStateWidget(
        message: context.l10n.serverPanelUnavailable(widget.config.panelType),
      );
    }
    if (!panel.needsCapabilities) {
      return panel.buildModules(context, widget.config, const {});
    }
    return FutureBuilder<Map<String, PanelAccess>>(
      future: _access,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ModuleErrorStateWidget(
            message: ErrorMessageUtils.userFacingMessage(snapshot.error!),
            onRetry: () => setState(() => _access = _readCapabilities()),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return panel.buildModules(context, widget.config, snapshot.requireData);
      },
    );
  }
}
