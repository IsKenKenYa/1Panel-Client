import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide Container;
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:onepanelapp_app/features/containers/widgets/container_logs_view.dart';
import 'package:onepanelapp_app/features/containers/widgets/container_stats_view.dart';
import 'package:onepanelapp_app/shared/widgets/app_card.dart';

class ContainerDetailPage extends StatefulWidget {
  final ContainerInfo container;

  const ContainerDetailPage({
    super.key,
    required this.container,
  });

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ContainerService();
  late ContainerInfo _container;

  @override
  void initState() {
    super.initState();
    _container = widget.container;
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text(_container.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.containerTabInfo),
            Tab(text: l10n.containerTabLogs),
            Tab(text: l10n.containerTabStats),
            Tab(text: l10n.containerTabTerminal),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(container: _container, service: _service),
          ContainerLogsView(containerId: _container.id),
          ContainerStatsView(containerId: _container.id),
          _TerminalTab(),
        ],
      ),
    );
  }
}

class _InfoTab extends StatefulWidget {
  final ContainerInfo container;
  final ContainerService service;

  const _InfoTab({
    required this.container,
    required this.service,
  });

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  String? _inspectData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInspectData();
  }

  Future<void> _loadInspectData() async {
    try {
      final data = await widget.service.inspectContainer(widget.container.id);
      if (!mounted) return;
      setState(() {
        _inspectData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(l10n.containerOperateFailed(_error!)));
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
                _InfoItem(label: l10n.containerInfoId, value: widget.container.id),
                _InfoItem(label: l10n.containerInfoName, value: widget.container.name),
                _InfoItem(label: l10n.containerInfoImage, value: widget.container.image),
                _InfoItem(label: l10n.containerInfoStatus, value: widget.container.status),
                _InfoItem(label: l10n.containerInfoCreated, value: widget.container.createTime ?? '-'),
                _InfoItem(
                    label: 'IP', value: widget.container.ipAddress ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_inspectData != null)
            AppCard(
              title: 'JSON',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _formatJson(_inspectData!),
                  style: TextStyle(
                    fontFamily: 'Monospace',
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

class _TerminalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.terminal, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.commonComingSoon),
        ],
      ),
    );
  }
}
