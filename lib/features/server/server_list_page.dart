import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_desktop.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_mobile.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({
    super.key,
    this.enableCoach = true,
  });

  final bool enableCoach;

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late final ServerListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServerListViewModel(
      enableCoach: widget.enableCoach,
      serverProvider: context.read<ServerProvider>(),
    );
    _viewModel.init(context);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PlatformUtils.isDesktop(context)
          ? const ServerListPageDesktop()
          : const ServerListPageMobile(),

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  final ServerCardViewModel data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        child: Padding(
          padding: AppDesignTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.config.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (data.isCurrent)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(l10n.serverCurrent),
                    ),
                  IconButton(
                    tooltip: l10n.commonDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              Text('${l10n.serverIpLabel}: ${_extractHost(data.config.url)}'),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                    icon: Icons.memory_outlined,
                    label: l10n.serverCpuLabel,
                    value: _percent(data.metrics.cpuPercent),
                  ),
                  _MetricPill(
                    icon: Icons.storage_outlined,
                    label: l10n.serverMemoryLabel,
                    value: _percent(data.metrics.memoryPercent),
                  ),
                  _MetricPill(
                    icon: Icons.speed_outlined,
                    label: l10n.serverLoadLabel,
                    value: _decimal(data.metrics.load),
                  ),
                  _MetricPill(
                    icon: Icons.sd_card_outlined,
                    label: l10n.serverDiskLabel,
                    value: _percent(data.metrics.diskPercent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractHost(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : url;
  }

  String _percent(double? value) {
    if (value == null) {
      return '--';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _decimal(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(2);
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text('$label $value'),
        ],
      ),
    );
  }
}
