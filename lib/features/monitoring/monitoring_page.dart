import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:onepanel_client/shared/widgets/metric_card.dart';
import 'package:onepanel_client/features/settings/monitor_settings_page.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';
import '../../data/models/monitoring_runtime_models.dart';
import '../../data/models/monitor_models.dart';
import 'monitoring_provider.dart';
import 'widgets/monitor_chart.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';

part 'monitoring_page_widgets.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.select((MonitoringProvider p) => p);
    return ServerAwarePageScaffold(
      title: l10n.serverModuleMonitoring,
      actions: [
        Selector<MonitoringProvider, bool>(
          selector: (_, p) => p.data.isLoading,
          builder: (context, loading, _) => IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: loading ? null : provider.refresh,
            tooltip: l10n.commonRefresh,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: l10n.monitorChartSettings,
          onPressed: () => _showSettingsDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.monitorSettingsTitle,
          onPressed: () => MonitorSettingsPage.open(context),
        ),
      ],
      body: PageVisibilityListener(
        key: ObjectKey(provider),
        onChanged: (visible) => provider.setPageVisible(this, visible),
        child: const _MonitoringBody(),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final provider = context.read<MonitoringProvider>();
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _MonitorSettingsDialog(),
      ),
    );
  }
}

class _MonitoringBody extends StatelessWidget {
  const _MonitoringBody();

  @override
  Widget build(BuildContext context) {
    final (loading, hasData, error) = context.select((MonitoringProvider p) {
      final data = p.data;
      final hasData = data.hasData;
      return (data.isLoading && !hasData, hasData, data.error);
    });
    final refresh = context.read<MonitoringProvider>().refresh;
    final spec = AdaptiveLayoutSpec.of(context);
    return PartialErrorToastListener(
      errorMessage: error,
      hasCachedData: hasData,
      onRetry: refresh,
      child: AsyncStatePageBodyWidget(
        isLoading: loading,
        errorMessage: hasData ? null : error,
        onRetry: refresh,
        child: AdaptiveWidthContainer(
          maxWidth: spec.dashboardMaxWidth,
          child: RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(builder: (context, constraints) {
              const metrics = _HistoryMetric.values;
              const gap = AppDesignTokens.spacingMd;
              final columns =
                  constraints.maxWidth - spec.pagePadding.horizontal >= 800
                      ? 2
                      : 1;
              return ListView(
                padding: spec.pagePadding,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const _CurrentMetrics(),
                  for (var i = 0; i < metrics.length; i += columns)
                    Padding(
                      padding: const EdgeInsets.only(top: gap),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _HistoryCard(metrics[i])),
                          if (columns == 2) ...[
                            const SizedBox(width: gap),
                            Expanded(
                                child: i + 1 < metrics.length
                                    ? _HistoryCard(metrics[i + 1])
                                    : const SizedBox.shrink()),
                          ],
                        ],
                      ),
                    ),
                  const _GpuCard(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

enum _HistoryMetric { cpu, memory, load, disk, network }

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.metric);

  final _HistoryMetric metric;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final series = context.select((MonitoringProvider p) => switch (metric) {
          _HistoryMetric.cpu => p.data.cpuTimeSeries,
          _HistoryMetric.memory => p.data.memoryTimeSeries,
          _HistoryMetric.load => p.data.loadTimeSeries,
          _HistoryMetric.disk => p.data.ioTimeSeries,
          _HistoryMetric.network => p.data.networkTimeSeries,
        });
    final (title, unit) = switch (metric) {
      _HistoryMetric.cpu => (l10n.serverCpuLabel, '%'),
      _HistoryMetric.memory => (l10n.serverMemoryLabel, '%'),
      _HistoryMetric.load => (l10n.serverLoadLabel, ''),
      _HistoryMetric.disk => ('${l10n.serverDiskLabel} IO', 'KB/s'),
      _HistoryMetric.network => (l10n.monitorNetworkLabel, 'KB/s'),
    };
    final disk = metric == _HistoryMetric.disk;
    Widget? deviceSelector;
    if (disk || metric == _HistoryMetric.network) {
      final (value, options) = context.select((MonitoringProvider p) => disk
          ? (p.data.selectedIO, p.data.ioOptions)
          : (p.data.selectedNetwork, p.data.networkOptions));
      final provider = context.read<MonitoringProvider>();
      deviceSelector = _MetricSelector(
        value: value,
        options: options,
        onChanged:
            disk ? provider.selectIOOption : provider.selectNetworkOption,
      );
    }
    return _ExpandableChartCard(
      key: PageStorageKey(metric),
      title: title,
      unit: unit,
      timeSeries: series,
      selector: deviceSelector,
      emptyHint: deviceSelector == null
          ? null
          : (disk ? l10n.monitorIoEmptyHint : l10n.monitorNetworkEmptyHint),
    );
  }
}

class _GpuCard extends StatelessWidget {
  const _GpuCard();

  @override
  Widget build(BuildContext context) {
    final gpuInfo = context.select((MonitoringProvider p) => p.data.gpuInfo);
    if (gpuInfo.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    return AppCard(
      title: l10n.monitorGPU,
      child: Column(
        children: gpuInfo.map((gpu) => _buildGPUItem(context, gpu)).toList(),
      ),
    );
  }

  Widget _buildGPUItem(BuildContext context, MonitorGpuInfo gpu) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gpu.name ?? 'GPU',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Row(
            children: [
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUUtilization,
                  value: gpu.utilization != null
                      ? '${gpu.utilization!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ),
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUMemory,
                  value: gpu.memory != null
                      ? '${gpu.memory!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ),
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUTemperature,
                  value: gpu.temperature != null
                      ? '${gpu.temperature!.toStringAsFixed(0)}°C'
                      : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentMetrics extends StatelessWidget {
  const _CurrentMetrics();

  @override
  Widget build(BuildContext context) {
    final metrics = context.select((MonitoringProvider p) {
      final data = p.data.currentMetrics;
      return data == null
          ? null
          : (
              cpuPercent: data.cpuPercent,
              memoryPercent: data.memoryPercent,
              diskPercent: data.diskPercent,
              load1: data.load1,
            );
    });
    final l10n = context.l10n;
    if (metrics == null) return const SizedBox.shrink();

    return AppCard(
      title: l10n.monitorMetricCurrent,
      child: MetricOverviewGrid(
        cpuPercent: metrics.cpuPercent,
        memoryPercent: metrics.memoryPercent,
        diskPercent: metrics.diskPercent,
        load: metrics.load1,
      ),
    );
  }
}
