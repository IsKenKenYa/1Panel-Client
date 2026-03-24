import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart' hide Container;
import 'package:onepanel_client/features/containers/providers/container_detail_provider.dart';
import 'package:onepanel_client/features/containers/widgets/container_logs_view.dart';
import 'package:onepanel_client/features/containers/widgets/container_stats_view.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            title: l10n.appBaseInfo,
            child: Column(
              children: [
                _InfoItem(label: l10n.containerInfoId, value: container.id),
                _InfoItem(label: l10n.containerInfoName, value: container.name),
                _InfoItem(label: l10n.containerInfoImage, value: container.image),
                _InfoItem(label: l10n.containerInfoStatus, value: container.status),
                _InfoItem(label: l10n.containerInfoCreated, value: container.createTime ?? '-'),
                _InfoItem(
                  label: l10n.serverIpLabel,
                  value: container.ipAddress ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (provider.inspectData != null)
            AppCard(
              title: l10n.containerInspectJson,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _formatJson(provider.inspectData!),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
