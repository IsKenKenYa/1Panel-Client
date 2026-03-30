import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide Container;
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';
import 'package:onepanel_client/features/containers/widgets/container_logs_view.dart';
import 'package:onepanel_client/features/containers/widgets/container_stats_view.dart';
import 'package:provider/provider.dart';

class ContainerDetailPage extends StatelessWidget {
  final ContainerInfo container;

  const ContainerDetailPage({
    super.key,
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContainerDetailProvider(container: container)..loadAll(),
      child: _ContainerDetailView(container: container),
    );
  }
}

class _ContainerDetailView extends StatefulWidget {
  final ContainerInfo container;

  const _ContainerDetailView({
    required this.container,
  });

  @override
  State<_ContainerDetailView> createState() => _ContainerDetailViewState();
}

class _ContainerDetailViewState extends State<_ContainerDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.container.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.containerTabInfo),
            Tab(text: l10n.containerTabLogs),
            Tab(text: l10n.containerTabStats),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(container: widget.container),
          const ContainerLogsView(),
          const ContainerStatsView(),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final ContainerInfo container;

  const _InfoTab({
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<ContainerDetailProvider>();

    if (provider.inspectLoading && provider.inspectData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.inspectError != null && provider.inspectData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.containerOperateFailed(provider.inspectError!)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: provider.loadInspect,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 基本信息卡片 ──
          _InfoCard(
            title: l10n.appBaseInfo,
            rows: [
              _InfoRow(
                icon: Icons.fingerprint,
                label: l10n.containerInfoId,
                value: container.id,
                mono: true,
              ),
              _InfoRow(
                icon: Icons.label_outline,
                label: l10n.containerInfoName,
                value: container.name,
              ),
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: l10n.containerInfoImage,
                value: container.image,
              ),
              _InfoRow(
                icon: Icons.circle_outlined,
                label: l10n.containerInfoStatus,
                value: container.status,
                valueColor: _stateColor(colorScheme, container.state),
              ),
              _InfoRow(
                icon: Icons.access_time_outlined,
                label: l10n.containerInfoCreated,
                value: container.createTime ?? '-',
              ),
              _InfoRow(
                icon: Icons.lan_outlined,
                label: l10n.serverIpLabel,
                value: container.ipAddress ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Inspect JSON ──
          if (provider.inspectData != null)
            _InspectJsonCard(
              title: l10n.containerInspectJson,
              jsonString: _formatJson(provider.inspectData!),
              scheme: colorScheme,
            ),
        ],
      ),
    );
  }

  Color _stateColor(ColorScheme scheme, String state) {
    switch (state.toLowerCase()) {
      case 'running':
        return scheme.tertiary;
      case 'dead':
      case 'removing':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  String _formatJson(String jsonString) {
    try {
      final dynamic parsed = json.decode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsed);
    } catch (e) {
      return jsonString;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 信息卡片（带标题 + 行列表）
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 行列表
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 48,
                    endIndent: 0,
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 单行信息项
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: (mono
                      ? textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace', fontSize: 11)
                      : textTheme.bodySmall)
                  ?.copyWith(
                color: valueColor ?? scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspect JSON 卡片
// ─────────────────────────────────────────────────────────────────────────────
class _InspectJsonCard extends StatefulWidget {
  const _InspectJsonCard({
    required this.title,
    required this.jsonString,
    required this.scheme,
  });
  final String title;
  final String jsonString;
  final ColorScheme scheme;

  @override
  State<_InspectJsonCard> createState() => _InspectJsonCardState();
}

class _InspectJsonCardState extends State<_InspectJsonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = widget.scheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 可折叠标题行
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Icon(Icons.data_object,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 折叠内容
          if (_expanded) ...[
            Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: SelectableText(
                widget.jsonString,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
