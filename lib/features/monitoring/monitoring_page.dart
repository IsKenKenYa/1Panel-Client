import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:provider/provider.dart';
import '../../data/models/monitoring_runtime_models.dart';
import '../../data/models/monitor_models.dart';
import '../../data/repositories/monitor_repository.dart';
import 'monitoring_provider.dart';
import 'widgets/monitor_chart.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MonitoringProvider>();
      provider.load();
      provider.loadGPUInfo();
      // 默认启用自动刷新
      provider.toggleAutoRefresh(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.serverModuleMonitoring,
      onServerChanged: _reloadForCurrentServer,
      actions: [
        Consumer<MonitoringProvider>(
          builder: (context, provider, _) => IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.data.isLoading ? null : provider.refresh,
            tooltip: l10n.commonRefresh,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: l10n.monitorSettings,
          onPressed: () => _showSettingsDialog(context),
        ),
      ],
      body: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Consumer<MonitoringProvider>(
          builder: (context, provider, _) {
            return _buildBody(context, provider.data, provider.refresh);
          },
        ),
      ),
    );
  }

  Future<void> _reloadForCurrentServer() async {
    if (!mounted) return;
    final provider = context.read<MonitoringProvider>();
    provider.load();
    provider.loadGPUInfo();
  }

  Widget _buildBody(
    BuildContext context,
    MonitoringData data,
    Future<void> Function() onRefresh,
  ) {
    final l10n = context.l10n;
    final hasData = data.currentMetrics != null ||
        data.cpuTimeSeries != null ||
        data.memoryTimeSeries != null;

    if (data.error != null && !hasData) {
      return ModuleErrorStateWidget(
        message: data.error,
        onRetry: onRefresh,
      );
    }

    if (data.isLoading && !hasData) {
      return const _LoadingView();
    }

    return PartialErrorToastListener(
      errorMessage: data.error,
      hasCachedData: hasData,
      onRetry: onRefresh,
      child: RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          _buildCurrentMetrics(context, data.currentMetrics),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildTimeSeriesCard(
            context,
            l10n.serverCpuLabel,
            data.cpuTimeSeries,
            '%',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.serverMemoryLabel,
            data.memoryTimeSeries,
            '%',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.serverLoadLabel,
            data.loadTimeSeries,
            '',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            '${l10n.serverDiskLabel} IO',
            data.ioTimeSeries,
            'KB/s',
            emptyHint: l10n.monitorIoEmptyHint,
            selector: _MetricSelector(
              value: data.selectedIO,
              options: data.ioOptions,
              onChanged: (value) =>
                  context.read<MonitoringProvider>().selectIOOption(value),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.monitorNetworkLabel,
            data.networkTimeSeries,
            'KB/s',
            emptyHint: l10n.monitorNetworkEmptyHint,
            selector: _MetricSelector(
              value: data.selectedNetwork,
              options: data.networkOptions,
              onChanged: (value) =>
                  context.read<MonitoringProvider>().selectNetworkOption(value),
            ),
          ),
          // GPU监控卡片（如果有GPU）
          if (data.gpuInfo.isNotEmpty) ...[
            const SizedBox(height: AppDesignTokens.spacingSm),
            _buildGPUCard(context, data.gpuInfo),
          ],
        ],
      ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MonitorSettingsDialog(),
    );
  }

  Widget _buildGPUCard(BuildContext context, List<MonitorGpuInfo> gpuInfo) {
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

  Widget _buildCurrentMetrics(
      BuildContext context, MonitorMetricsSnapshot? metrics) {
    final l10n = context.l10n;
    if (metrics == null) return const SizedBox.shrink();

    return AppCard(
      title: l10n.monitorMetricCurrent,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppDesignTokens.spacingSm,
        crossAxisSpacing: AppDesignTokens.spacingSm,
        // 2.15：容纳 labelSmall + headlineSmall + 趋势条在系统大字体下不溢出。
        childAspectRatio: 2.15,
        children: [
          _HealthTile(
            label: l10n.serverCpuLabel,
            value: metrics.cpuPercent != null
                ? '${metrics.cpuPercent!.toStringAsFixed(1)}%'
                : '--',
            percent: metrics.cpuPercent,
            icon: Icons.memory_outlined,
          ),
          _HealthTile(
            label: l10n.serverMemoryLabel,
            value: metrics.memoryPercent != null
                ? '${metrics.memoryPercent!.toStringAsFixed(1)}%'
                : '--',
            percent: metrics.memoryPercent,
            icon: Icons.storage_outlined,
          ),
          _HealthTile(
            label: l10n.serverDiskLabel,
            value: metrics.diskPercent != null
                ? '${metrics.diskPercent!.toStringAsFixed(1)}%'
                : '--',
            percent: metrics.diskPercent,
            icon: Icons.folder_outlined,
          ),
          _HealthTile(
            label: l10n.serverLoadLabel,
            value: metrics.load1 != null
                ? metrics.load1!.toStringAsFixed(2)
                : '--',
            percent: null,
            icon: Icons.speed_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesCard(BuildContext context, String title,
      MonitorTimeSeries? timeSeries, String unit,
      {Widget? selector, String? emptyHint}) {
    return _ExpandableChartCard(
      title: title,
      timeSeries: timeSeries,
      unit: unit,
      selector: selector,
      emptyHint: emptyHint,
    );
  }
}

