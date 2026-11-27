import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/panels/dpanel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

class DPanelModuleSections extends StatefulWidget {
  const DPanelModuleSections({
    super.key,
    required this.server,
    required this.capabilities,
  });

  final ApiConfig server;
  final Map<String, PanelAccess> capabilities;

  @override
  State<DPanelModuleSections> createState() => _DPanelModuleSectionsState();
}

class _DPanelModuleSectionsState extends State<DPanelModuleSections> {
  DPanelOverview? _overview;
  List<DPanelContainerSummary> _containers = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _operatingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<DPanelSession> _resolveSession() async {
    final session = await PanelRegistry.instance.savedSessionFor(widget.server);
    if (session is! DPanelSession) {
      throw StateError('DPanel session unavailable');
    }
    return session;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _resolveSession();
      final (overview, containers) = await (
        session.loadOverview(),
        session.listContainers(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _containers = containers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageUtils.userFacingMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _operateContainer(
    DPanelContainerSummary container,
    String operate,
  ) async {
    if (_operatingIds.contains(container.id)) return;
    final l10n = context.l10n;
    if (operate == 'stop' || operate == 'restart') {
      final confirmed = await ConfirmActionSheetWidget.show(
        context,
        title: operate == 'stop' ? l10n.commonStop : l10n.commonRestart,
        message: '${container.name} (${container.image})',
        confirmLabel: operate == 'stop' ? l10n.commonStop : l10n.commonRestart,
        isDestructive: operate == 'stop',
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _operatingIds.add(container.id));
    try {
      final session = await _resolveSession();
      await session.operateContainer(container.id, operate);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      await _load();
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        l10n.containerOperateFailed(ErrorMessageUtils.userFacingMessage(error)),
      );
    } finally {
      if (mounted) {
        setState(() => _operatingIds.remove(container.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading && _overview == null && _containers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDesignTokens.spacingXl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && _overview == null && _containers.isEmpty) {
      return ModuleErrorStateWidget(message: _error!, onRetry: _load);
    }

    final overview = _overview;
    final canWriteContainers =
        widget.capabilities['containers'] == PanelAccess.write;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview != null) ...[
          SectionPropertyList(
            title: 'DPanel',
            actions: [
              TextButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRefresh),
              ),
            ],
            properties: [
              SectionProperty(
                label: l10n.commonVersion,
                value: overview.panelVersion,
              ),
              SectionProperty(
                label: 'Docker',
                value: overview.dockerVersion,
              ),
              SectionProperty(
                label: 'OS',
                value: overview.operatingSystem,
              ),
              SectionProperty(
                label: l10n.serverModuleContainers,
                value: overview.containerCount == null
                    ? '${_containers.length}'
                    : '${overview.runningCount ?? 0} / ${overview.containerCount}',
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
        ],
        SectionCard(
          title: l10n.serverModuleContainers,
          isBusy: _loading,
          action: overview == null
              ? TextButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRefresh),
                )
              : null,
          child: _containers.isEmpty
              ? ExpressiveHint(message: l10n.commonEmpty)
              : Column(
                  children: [
                    for (final (index, container) in _containers.indexed) ...[
                      ExpressiveRow(
                        title: container.name,
                        subtitle: container.image,
                        meta: [
                          if (container.state.isNotEmpty) container.state,
                          if (container.status.isNotEmpty) container.status,
                        ],
                        leadingIcon: container.isRunning
                            ? Icons.play_circle_outline
                            : Icons.stop_circle_outlined,
                        trailing: canWriteContainers
                            ? _buildActions(context, container)
                            : null,
                      ),
                      if (index < _containers.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: AppDesignTokens.spacingLg,
                          endIndent: AppDesignTokens.spacingLg,
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, DPanelContainerSummary container) {
    final l10n = context.l10n;
    if (_operatingIds.contains(container.id)) {
      return const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return PopupMenuButton<String>(
      onSelected: (action) => _operateContainer(container, action),
      itemBuilder: (_) => [
        if (!container.isRunning)
          PopupMenuItem(value: 'start', child: Text(l10n.commonStart)),
        if (container.isRunning)
          PopupMenuItem(value: 'stop', child: Text(l10n.commonStop)),
        PopupMenuItem(value: 'restart', child: Text(l10n.commonRestart)),
      ],
    );
  }
}
